import 'dart:math' as math;
import 'dart:typed_data';

/// Pembaca minimal file Excel lama `.xls` (BIFF8 di dalam kontainer OLE2).
///
/// Paket XLSX yang dipakai aplikasi tidak bisa membaca format biner lama,
/// padahal banyak laporan bank/e-wallet dan file Excel 97–2003 masih memakai
/// `.xls`. Pembaca ini hanya mengambil **nilai sel** (teks, angka, tanggal,
/// hasil rumus) dari setiap worksheet — format, gaya, dan grafik diabaikan.
///
/// Tanggal (angka dengan format tanggal) dikembalikan sebagai `yyyy-mm-dd`;
/// angka bulat tanpa desimal; teks apa adanya.
class LegacyXlsReader {
  LegacyXlsReader._();

  static const List<int> signature = [
    0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1, //
  ];

  /// Isi setiap worksheet (urut seperti di file) sebagai baris × kolom teks.
  static List<List<List<String>>> readSheets(List<int> bytes) {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final container = _CompoundFile(data);
    final workbook = container.stream('Workbook');
    if (workbook != null) return _Biff8Workbook(workbook).sheets();
    if (container.stream('Book') != null) {
      throw const FormatException(
        'File Excel 95 terlalu lama. Simpan ulang sebagai .xlsx atau .csv.',
      );
    }
    throw const FormatException('File .xls tidak berisi data workbook.');
  }
}

// ── Kontainer OLE2 / Compound File Binary ────────────────────────────────────

class _CompoundFile {
  _CompoundFile(this._data) {
    if (_data.length < 512 ||
        !Iterable<int>.generate(
          8,
        ).every((i) => _data[i] == LegacyXlsReader.signature[i])) {
      throw const FormatException('Bukan file .xls yang valid.');
    }
    final header = ByteData.sublistView(_data, 0, 512);
    _sectorSize = 1 << header.getUint16(0x1E, Endian.little);
    _miniSectorSize = 1 << header.getUint16(0x20, Endian.little);
    final fatSectorCount = header.getUint32(0x2C, Endian.little);
    final firstDirSector = header.getUint32(0x30, Endian.little);
    _miniCutoff = header.getUint32(0x38, Endian.little);
    final firstMiniFat = header.getUint32(0x3C, Endian.little);
    var difatSector = header.getUint32(0x44, Endian.little);

    // Daftar sektor FAT: 109 pertama di header, sisanya di rantai DIFAT.
    final fatSectors = <int>[];
    for (var i = 0; i < 109 && fatSectors.length < fatSectorCount; i++) {
      fatSectors.add(header.getUint32(0x4C + i * 4, Endian.little));
    }
    final perDifat = _sectorSize ~/ 4 - 1;
    var guard = 0;
    while (fatSectors.length < fatSectorCount &&
        difatSector < _maxRegularSector &&
        guard++ < 100000) {
      final view = _sectorView(difatSector);
      for (var i = 0; i < perDifat && fatSectors.length < fatSectorCount; i++) {
        fatSectors.add(view.getUint32(i * 4, Endian.little));
      }
      difatSector = view.getUint32(perDifat * 4, Endian.little);
    }

    final fat = <int>[];
    for (final sector in fatSectors) {
      final view = _sectorView(sector);
      for (var i = 0; i < _sectorSize ~/ 4; i++) {
        fat.add(view.getUint32(i * 4, Endian.little));
      }
    }
    _fat = fat;

    final dir = _readChain(firstDirSector, _fat, _sectorSize, _regularSector);
    _entries = [
      for (var off = 0; off + 128 <= dir.length; off += 128)
        _DirEntry.parse(ByteData.sublistView(dir, off, off + 128)),
    ];

    _miniFat = [];
    if (firstMiniFat < _maxRegularSector) {
      final raw = _readChain(firstMiniFat, _fat, _sectorSize, _regularSector);
      final view = ByteData.sublistView(raw);
      for (var i = 0; i + 4 <= raw.length; i += 4) {
        _miniFat.add(view.getUint32(i, Endian.little));
      }
    }
    final root = _entries.isNotEmpty ? _entries.first : null;
    _miniStream = root == null || root.start >= _maxRegularSector
        ? Uint8List(0)
        : _readChain(root.start, _fat, _sectorSize, _regularSector);
  }

  static const int _maxRegularSector = 0xFFFFFFFA;

  final Uint8List _data;
  late final int _sectorSize;
  late final int _miniSectorSize;
  late final int _miniCutoff;
  late final List<int> _fat;
  late final List<int> _miniFat;
  late final List<_DirEntry> _entries;
  late final Uint8List _miniStream;

  ByteData _sectorView(int sector) {
    final start = (sector + 1) * _sectorSize;
    if (start + _sectorSize > _data.length) {
      throw const FormatException('File .xls terpotong atau rusak.');
    }
    return ByteData.sublistView(_data, start, start + _sectorSize);
  }

  Uint8List _regularSector(int sector) {
    final start = (sector + 1) * _sectorSize;
    final end = math.min(start + _sectorSize, _data.length);
    if (start >= end) {
      throw const FormatException('File .xls terpotong atau rusak.');
    }
    return Uint8List.sublistView(_data, start, end);
  }

  Uint8List _miniSector(int sector) {
    final start = sector * _miniSectorSize;
    final end = math.min(start + _miniSectorSize, _miniStream.length);
    if (start >= end) {
      throw const FormatException('File .xls terpotong atau rusak.');
    }
    return Uint8List.sublistView(_miniStream, start, end);
  }

  Uint8List _readChain(
    int start,
    List<int> table,
    int sectorSize,
    Uint8List Function(int) sectorAt,
  ) {
    final out = BytesBuilder(copy: false);
    var sector = start;
    var guard = 0;
    while (sector < _maxRegularSector && sector < table.length) {
      if (guard++ > table.length) {
        throw const FormatException('Rantai sektor .xls berputar (rusak).');
      }
      out.add(sectorAt(sector));
      sector = table[sector];
    }
    return out.takeBytes();
  }

  /// Isi stream bernama [name], atau null bila tidak ada.
  Uint8List? stream(String name) {
    for (final entry in _entries) {
      if (entry.type != 2 || entry.name != name) continue;
      final raw = entry.size < _miniCutoff
          ? _readChain(entry.start, _miniFat, _miniSectorSize, _miniSector)
          : _readChain(entry.start, _fat, _sectorSize, _regularSector);
      return Uint8List.sublistView(raw, 0, math.min(entry.size, raw.length));
    }
    return null;
  }
}

class _DirEntry {
  _DirEntry(this.name, this.type, this.start, this.size);

  factory _DirEntry.parse(ByteData view) {
    final nameBytes = math.min(view.getUint16(0x40, Endian.little), 64);
    final codeUnits = <int>[
      for (var i = 0; i + 1 < nameBytes; i += 2)
        view.getUint16(i, Endian.little),
    ];
    while (codeUnits.isNotEmpty && codeUnits.last == 0) {
      codeUnits.removeLast();
    }
    return _DirEntry(
      String.fromCharCodes(codeUnits),
      view.getUint8(0x42),
      view.getUint32(0x74, Endian.little),
      view.getUint32(0x78, Endian.little),
    );
  }

  final String name;
  final int type;
  final int start;
  final int size;
}

// ── Workbook BIFF8 ───────────────────────────────────────────────────────────

class _Record {
  _Record(this.id, this.offset, this.data);

  final int id;

  /// Posisi awal record (header) di stream — dipakai BOUNDSHEET.
  final int offset;
  final Uint8List data;
}

class _Biff8Workbook {
  _Biff8Workbook(this._stream);

  final Uint8List _stream;

  static const int _bof = 0x0809;
  static const int _eof = 0x000A;
  static const int _filePass = 0x002F;
  static const int _continue = 0x003C;
  static const int _boundSheet = 0x0085;
  static const int _sstId = 0x00FC;
  static const int _format = 0x041E;
  static const int _xf = 0x00E0;
  static const int _labelSst = 0x00FD;
  static const int _label = 0x0204;
  static const int _rString = 0x00D6;
  static const int _number = 0x0203;
  static const int _rk = 0x027E;
  static const int _mulRk = 0x00BD;
  static const int _formula = 0x0006;
  static const int _string = 0x0207;
  static const int _boolErr = 0x0205;

  final List<String> _sst = [];
  final Map<int, String> _formats = {};
  final List<int> _xfFormat = [];

  List<_Record> _records() {
    final records = <_Record>[];
    final view = ByteData.sublistView(_stream);
    var pos = 0;
    while (pos + 4 <= _stream.length) {
      final id = view.getUint16(pos, Endian.little);
      final len = view.getUint16(pos + 2, Endian.little);
      final end = math.min(pos + 4 + len, _stream.length);
      records.add(
        _Record(id, pos, Uint8List.sublistView(_stream, pos + 4, end)),
      );
      pos = end;
    }
    return records;
  }

  List<List<List<String>>> sheets() {
    final records = _records();
    final sheetOffsets = <int>[];

    // Substream global: dari awal sampai EOF pertama.
    var i = 0;
    for (; i < records.length; i++) {
      final r = records[i];
      if (r.id == _eof) break;
      switch (r.id) {
        case _filePass:
          throw const FormatException(
            'File .xls ini dikunci password. Buka di Excel, hapus '
            'password-nya, lalu simpan ulang.',
          );
        case _boundSheet:
          // Hanya worksheet biasa (bukan chart/macro sheet).
          if (r.data.length >= 6 && r.data[5] == 0) {
            sheetOffsets.add(
              ByteData.sublistView(r.data).getUint32(0, Endian.little),
            );
          }
        case _format:
          if (r.data.length >= 5) {
            final reader = _ChunkReader([r.data]);
            final index = reader.uint16();
            _formats[index] = reader.unicodeString(lengthBytes: 2);
          }
        case _xf:
          if (r.data.length >= 4) {
            _xfFormat.add(
              ByteData.sublistView(r.data).getUint16(2, Endian.little),
            );
          }
        case _sstId:
          final chunks = [r.data];
          while (i + 1 < records.length && records[i + 1].id == _continue) {
            chunks.add(records[++i].data);
          }
          _readSst(chunks);
      }
    }

    final byOffset = {for (final (k, r) in records.indexed) r.offset: k};
    return [
      for (final offset in sheetOffsets)
        if (byOffset[offset] case final start?) _readSheet(records, start),
    ];
  }

  void _readSst(List<Uint8List> chunks) {
    final reader = _ChunkReader(chunks);
    reader.uint32(); // total referensi
    final unique = reader.uint32();
    for (var n = 0; n < unique && !reader.isAtEnd; n++) {
      _sst.add(reader.unicodeString(lengthBytes: 2));
    }
  }

  List<List<String>> _readSheet(List<_Record> records, int start) {
    if (records[start].id != _bof) return const [];
    final cells = <int, Map<int, String>>{};
    var maxCol = -1;
    (int, int)? pendingFormula;

    void put(int row, int col, String value) {
      if (value.isEmpty) return;
      (cells[row] ??= {})[col] = value;
      maxCol = math.max(maxCol, col);
    }

    for (var i = start + 1; i < records.length; i++) {
      final r = records[i];
      if (r.id == _eof) break;
      if (r.data.length < 6 && r.id != _string) continue;
      final view = ByteData.sublistView(r.data);
      final row = r.data.length >= 2 ? view.getUint16(0, Endian.little) : 0;
      final col = r.data.length >= 4 ? view.getUint16(2, Endian.little) : 0;

      switch (r.id) {
        case _labelSst when r.data.length >= 10:
          final index = view.getUint32(6, Endian.little);
          if (index < _sst.length) put(row, col, _sst[index]);
        case _label || _rString:
          put(
            row,
            col,
            _ChunkReader([
              Uint8List.sublistView(r.data, 6),
            ]).unicodeString(lengthBytes: 2),
          );
        case _number when r.data.length >= 14:
          final xf = view.getUint16(4, Endian.little);
          put(row, col, _numberText(view.getFloat64(6, Endian.little), xf));
        case _rk when r.data.length >= 10:
          final xf = view.getUint16(4, Endian.little);
          put(
            row,
            col,
            _numberText(_decodeRk(view.getUint32(6, Endian.little)), xf),
          );
        case _mulRk:
          // row, kolom pertama, lalu (xf, rk) × n, lalu kolom terakhir.
          final count = (r.data.length - 6) ~/ 6;
          for (var k = 0; k < count; k++) {
            final base = 4 + k * 6;
            final xf = view.getUint16(base, Endian.little);
            final rk = _decodeRk(view.getUint32(base + 2, Endian.little));
            put(row, col + k, _numberText(rk, xf));
          }
        case _formula when r.data.length >= 14:
          final xf = view.getUint16(4, Endian.little);
          if (view.getUint16(12, Endian.little) != 0xFFFF) {
            put(row, col, _numberText(view.getFloat64(6, Endian.little), xf));
          } else if (r.data[6] == 0) {
            // Hasil teks ada di record STRING berikutnya.
            pendingFormula = (row, col);
          } else if (r.data[6] == 1) {
            put(row, col, r.data[8] != 0 ? 'TRUE' : 'FALSE');
          }
        case _string:
          if (pendingFormula case (final fRow, final fCol)) {
            put(
              fRow,
              fCol,
              _ChunkReader([r.data]).unicodeString(lengthBytes: 2),
            );
            pendingFormula = null;
          }
        case _boolErr when r.data.length >= 8:
          if (r.data[7] == 0) put(row, col, r.data[6] != 0 ? 'TRUE' : 'FALSE');
      }
    }

    if (cells.isEmpty) return const [];
    final maxRow = cells.keys.reduce(math.max);
    return [
      for (var row = 0; row <= maxRow; row++)
        [for (var col = 0; col <= maxCol; col++) cells[row]?[col] ?? ''],
    ];
  }

  /// Nilai RK: angka 30-bit bulat atau 30 bit atas double, opsional ÷100.
  static double _decodeRk(int rk) {
    double value;
    if (rk & 0x02 != 0) {
      var integer = rk >> 2;
      if (integer & 0x20000000 != 0) integer -= 0x40000000; // tanda 30-bit
      value = integer.toDouble();
    } else {
      // 30 bit atas = 32 bit tinggi sebuah double; 32 bit rendah nol.
      final bytes = ByteData(8)..setUint32(0, rk & 0xFFFFFFFC);
      value = bytes.getFloat64(0);
    }
    return rk & 0x01 != 0 ? value / 100 : value;
  }

  String _numberText(double value, int xf) {
    if (value.isNaN || value.isInfinite) return '';
    if (_isDateXf(xf) && value >= 1 && value < 2958466) {
      final date = DateTime.utc(
        1899,
        12,
        30,
      ).add(Duration(days: value.floor()));
      return '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.round().toString();
    }
    return value.toString();
  }

  bool _isDateXf(int xf) {
    if (xf >= _xfFormat.length) return false;
    final format = _xfFormat[xf];
    if ((format >= 14 && format <= 22) || (format >= 45 && format <= 47)) {
      return true;
    }
    final code = _formats[format];
    if (code == null) return false;
    // Buang teks berkutip, [warna/locale], dan escape sebelum mencari d/m/y.
    final cleaned = code
        .replaceAll(RegExp(r'"[^"]*"'), '')
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .replaceAll(RegExp(r'\\.'), '')
        .toLowerCase();
    return RegExp('[dy]').hasMatch(cleaned) ||
        (cleaned.contains('m') && !cleaned.contains('0'));
  }
}

/// Membaca data yang terpecah ke beberapa record CONTINUE. Saat karakter
/// sebuah string terpotong batas record, potongan berikutnya diawali satu
/// byte flag baru (8-bit / 16-bit) — ditangani di [unicodeString].
class _ChunkReader {
  _ChunkReader(this._chunks);

  final List<Uint8List> _chunks;
  int _chunk = 0;
  int _pos = 0;

  bool get isAtEnd {
    _skipExhausted();
    return _chunk >= _chunks.length;
  }

  void _skipExhausted() {
    while (_chunk < _chunks.length && _pos >= _chunks[_chunk].length) {
      _chunk++;
      _pos = 0;
    }
  }

  int byte() {
    _skipExhausted();
    if (_chunk >= _chunks.length) {
      throw const FormatException('Data teks .xls terpotong.');
    }
    return _chunks[_chunk][_pos++];
  }

  int uint16() => byte() | (byte() << 8);

  int uint32() => uint16() | (uint16() << 16);

  void skip(int count) {
    for (var i = 0; i < count; i++) {
      byte();
    }
  }

  /// XLUnicodeString BIFF8: panjang (1/2 byte), flag, [run], [ext], karakter.
  String unicodeString({required int lengthBytes}) {
    final length = lengthBytes == 2 ? uint16() : byte();
    final flags = byte();
    var highByte = flags & 0x01 != 0;
    final runs = flags & 0x08 != 0 ? uint16() : 0;
    final extSize = flags & 0x04 != 0 ? uint32() : 0;

    final units = <int>[];
    while (units.length < length) {
      if (_chunk < _chunks.length && _pos >= _chunks[_chunk].length) {
        // Lanjut di record CONTINUE: byte pertama = flag lebar karakter.
        _chunk++;
        _pos = 0;
        if (_chunk >= _chunks.length) break;
        highByte = byte() & 0x01 != 0;
        continue;
      }
      if (_chunk >= _chunks.length) break;
      units.add(highByte ? byte() | (byte() << 8) : byte());
    }
    skip(runs * 4 + extSize);
    // 8-bit = Latin-1 terkompresi, 16-bit = UTF-16LE; keduanya kode Unicode.
    return String.fromCharCodes(units);
  }
}
