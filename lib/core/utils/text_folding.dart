/// Las letras con tilde, diéresis o cedilla y la letra base con la que se comparan.
const Map<String, String> _baseLetters = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ñ': 'n', 'ç': 'c',
};

/// El texto en minúsculas y sin tildes, para ordenar y buscar sin que "Álamo" quede después de "zeta" ni
/// que escribir "camara" no encuentre "Cámara".
String foldForComparison(String text) {
  final folded = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final letter = String.fromCharCode(rune);
    folded.write(_baseLetters[letter] ?? letter);
  }
  return folded.toString();
}
