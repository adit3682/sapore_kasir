/// Mengubah teks struk (hasil formatReceipt) menjadi perintah ESC/POS standar.
/// Printer thermal murah umumnya hanya paham ASCII, jadi karakter lain disederhanakan.
List<int> buildEscPos(String text, {int feedLines = 3, bool cut = true}) {
  const map = {
    'É': 'E', 'é': 'e', 'è': 'e', 'È': 'E', 'à': 'a', 'ü': 'u', 'ö': 'o',
    '×': 'x', '·': '-', '—': '-', '–': '-', '’': "'", '“': '"', '”': '"',
  };

  List<int> ascii(String s) {
    final out = <int>[];
    for (final r in s.runes) {
      final ch = map[String.fromCharCode(r)] ?? String.fromCharCode(r);
      for (final u in ch.codeUnits) {
        out.add(u >= 32 && u <= 126 ? u : 63); // di luar ASCII cetak: '?'
      }
    }
    return out;
  }

  final bytes = <int>[0x1B, 0x40]; // ESC @  : reset printer
  for (final line in text.split('\n')) {
    final bold = line.trimLeft().startsWith('TOTAL');
    if (bold) bytes.addAll(const [0x1B, 0x45, 0x01]); // ESC E 1 : tebal
    bytes.addAll(ascii(line));
    if (bold) bytes.addAll(const [0x1B, 0x45, 0x00]);
    bytes.add(0x0A);
  }
  bytes.addAll([0x1B, 0x64, feedLines]); // ESC d n : maju n baris
  if (cut) bytes.addAll(const [0x1D, 0x56, 0x42, 0x00]); // GS V B 0 : potong parsial
  return bytes;
}
