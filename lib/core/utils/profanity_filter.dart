class ProfanityFilter {
  static bool hasProfanity(String text) {
    if (text.isEmpty) return false;
    final lowercaseText = text.toLowerCase();
    
    const substringWords = [
      // English
      'fuck', 'shit', 'bitch', 'asshole', 'cunt', 'motherfucker', 'dickhead',
      'nigger', 'nigga', 'faggot', 'bastard', 'bullshit', 'dumbass', 'jackass',
      'dipshit', 'horseshit', 'wanker', 'douchebag', 'skank', 'bollocks',
      'knobhead', 'retard', 'bitchass',
      // Tagalog
      'putangina', 'tangina', 'pokpok', 'tarantado', 'punyeta', 'kantot',
      'pakyu', 'pota', 'puta', 'pucha', 'burat', 'tamod', 'kupal', 'jakol',
      'salsal', 'kayat', 'iyot', 'amputa', 'pitingina', 'putragis', 'hindot',
      'gago', 'gaga', 'inutil', 'hinayupak', 'bwisit', 'lintik', 'lintek', 'syet'
    ];
    
    const boundaryWords = [
      // English
      'dick', 'pussy', 'whore', 'slut', 'cum', 'prick', 'twat', 'cock',
      'boobs', 'tits', 'kys', 'nazi', 'crap', 'ass', 'hoe',
      // Tagalog
      'tanga', 'bobo', 'malandi', 'ulol', 'hayop', 'suso', 'bayag', 'tite',
      'titi', 'tangengot', 'tae', 'pepe', 'puke', 'kiki', 'tumbong', 'bakla',
      'bading', 'abnoy', 'timang', 'ungas', 'buang', 'bayo'
    ];

    for (final word in substringWords) {
      if (lowercaseText.contains(word)) return true;
    }

    for (final word in boundaryWords) {
      final regex = RegExp('\\b$word\\b', caseSensitive: false);
      if (regex.hasMatch(lowercaseText)) return true;
    }

    return false;
  }
}
