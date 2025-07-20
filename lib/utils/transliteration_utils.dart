class TransliterationUtils {
  // Hindi to English transliteration mapping
  static const Map<String, String> _hindiToEnglish = {
    // Vowels
    'अ': 'a', 'आ': 'aa', 'इ': 'i', 'ई': 'ee', 'उ': 'u', 'ऊ': 'oo', 
    'ए': 'e', 'ऐ': 'ai', 'ओ': 'o', 'औ': 'au', 'ं': 'n', 'ः': 'h',
    
    // Consonants
    'क': 'k', 'ख': 'kh', 'ग': 'g', 'घ': 'gh', 'ङ': 'ng',
    'च': 'ch', 'छ': 'chh', 'ज': 'j', 'झ': 'jh', 'ञ': 'ny',
    'ट': 't', 'ठ': 'th', 'ड': 'd', 'ढ': 'dh', 'ण': 'n',
    'त': 't', 'थ': 'th', 'द': 'd', 'ध': 'dh', 'न': 'n',
    'प': 'p', 'फ': 'ph', 'ब': 'b', 'भ': 'bh', 'म': 'm',
    'य': 'y', 'र': 'r', 'ल': 'l', 'व': 'v', 'श': 'sh',
    'ष': 'sh', 'स': 's', 'ह': 'h', 'क्ष': 'ksh', 'त्र': 'tr', 'ज्ञ': 'gya',
    
    // Vowel signs (matras)
    'ा': 'aa', 'ि': 'i', 'ी': 'ee', 'ु': 'u', 'ू': 'oo',
    'े': 'e', 'ै': 'ai', 'ो': 'o', 'ौ': 'au', '्': '',
    
    // Numbers
    '०': '0', '१': '1', '२': '2', '३': '3', '४': '4',
    '५': '5', '६': '6', '७': '7', '८': '8', '९': '9',
    
    // Common conjuncts and special cases
    'च्च': 'chch', 'क्क': 'kk', 'त्त': 'tt', 'प्प': 'pp',
    'म्म': 'mm', 'न्न': 'nn', 'ल्ल': 'll', 'स्स': 'ss',
    'श्श': 'shsh', 'र्र': 'rr', 'द्द': 'dd', 'ब्ब': 'bb',
    
    // Special combinations
    'क्य': 'ky', 'ख्य': 'khy', 'ग्य': 'gy', 'घ्य': 'ghy',
    'च्य': 'chy', 'ज्य': 'jy', 'ट्य': 'ty', 'ड्य': 'dy',
    'त्य': 'ty', 'द्य': 'dy', 'न्य': 'ny', 'प्य': 'py',
    'ब्य': 'by', 'म्य': 'my', 'य्य': 'yy',
    'ल्य': 'ly', 'व्य': 'vy', 'श्य': 'shy', 'स्य': 'sy',
    'ह्य': 'hy',
    
    // र् combinations
    'र्क': 'rk', 'र्ख': 'rkh', 'र्ग': 'rg', 'र्घ': 'rgh',
    'र्च': 'rch', 'र्छ': 'rchh', 'र्ज': 'rj', 'र्झ': 'rjh',
    'र्ट': 'rt', 'र्ठ': 'rth', 'र्ड': 'rd', 'र्ढ': 'rdh',
    'र्त': 'rta', 'र्थ': 'rtha', 'र्द': 'rda', 'र्ध': 'rdha',
    'र्न': 'rn', 'र्प': 'rp', 'र्फ': 'rph', 'र्ब': 'rb',
    'र्भ': 'rbh', 'र्म': 'rm', 'र्य': 'rya', 'र्ल': 'rl',
    'र्व': 'rv', 'र्श': 'rsh', 'र्ष': 'rsha', 'र्स': 'rs',
    'र्ह': 'rh',
  };

  // English to Hindi phonetic mapping (reverse mapping with common variations)
  static const Map<String, List<String>> _englishToHindiPhonetic = {
    'a': ['अ', 'आ'],
    'aa': ['आ', 'ा'],
    'i': ['इ', 'ि'],
    'ee': ['ई', 'ी'],
    'u': ['उ', 'ु'],
    'oo': ['ऊ', 'ू'],
    'e': ['ए', 'े'],
    'ai': ['ऐ', 'ै'],
    'o': ['ओ', 'ो'],
    'au': ['औ', 'ौ'],
    
    'k': ['क', 'क्'],
    'kh': ['ख', 'ख्'],
    'g': ['ग', 'ग्'],
    'gh': ['घ', 'घ्'],
    'ch': ['च', 'च्'],
    'chh': ['छ', 'छ्'],
    'j': ['ज', 'ज्'],
    'jh': ['झ', 'झ्'],
    't': ['त', 'त्', 'ट', 'ट्'],
    'th': ['थ', 'थ्', 'ठ', 'ठ्'],
    'd': ['द', 'द्', 'ड', 'ड्'],
    'dh': ['ध', 'ध्', 'ढ', 'ढ्'],
    'n': ['न', 'न्', 'ण', 'ण्', 'ं'],
    'p': ['प', 'प्'],
    'ph': ['फ', 'फ्'],
    'b': ['ब', 'ब्'],
    'bh': ['भ', 'भ्'],
    'm': ['म', 'म्'],
    'y': ['य', 'य्'],
    'r': ['र', 'र्'],
    'l': ['ल', 'ल्'],
    'v': ['व', 'व्'],
    'w': ['व', 'व्'], // Alternative for 'v'
    'sh': ['श', 'श्', 'ष', 'ष्'],
    's': ['स', 'स्'],
    'h': ['ह', 'ह्', 'ः'],
    
    // Common English spellings for Hindi words
    'gyan': ['ज्ञान', 'ग्यान'],
    'dhyan': ['ध्यान'],
    'yoga': ['योग'],
    'yog': ['योग'],
    'mantra': ['मंत्र', 'मन्त्र'],
    'guru': ['गुरु'],
    'shanti': ['शांति', 'शान्ति'],
    'peace': ['शांति', 'शान्ति'],
    'om': ['ओम', 'ॐ'],
    'aum': ['ॐ', 'ओम'],
    'meditation': ['ध्यान', 'मेडिटेशन'],
    'sadhana': ['साधना'],
    'bhakti': ['भक्ति'],
    'karma': ['कर्म'],
    'dharma': ['धर्म'],
    'moksha': ['मोक्ष'],
    'mukti': ['मुक्ति'],
    'atma': ['आत्मा'],
    'brahma': ['ब्रह्म'],
    'vishnu': ['विष्णु'],
    'shiva': ['शिव'],
    'krishna': ['कृष्ण'],
    'rama': ['राम'],
    'hanuman': ['हनुमान'],
    'ganga': ['गंगा'],
    'gita': ['गीता'],
    'veda': ['वेद'],
    'upanishad': ['उपनिषद'],
    'sutra': ['सूत्र'],
    'tantra': ['तंत्र'],
    'yantra': ['यंत्र'],
    'chakra': ['चक्र'],
    'kundalini': ['कुंडलिनी'],
    'prana': ['प्राण'],
    'pranayama': ['प्राणायाम'],
    'asana': ['आसन'],
    'mudra': ['मुद्रा'],
    'bandha': ['बंध'],
    'samadhi': ['समाधि'],
    'nirvana': ['निर्वाण'],
    'satsang': ['सत्संग'],
    'kirtan': ['कीर्तन'],
    'bhajan': ['भजन'],
    'aarti': ['आरती'],
    'puja': ['पूजा'],
    'havan': ['हवन'],
    'yagna': ['यज्ञ'],
    'tapas': ['तपस'],
    'seva': ['सेवा'],
    'daan': ['दान'],
    'bhiksha': ['भिक्षा'],
    'sannyasa': ['संन्यास'],
    'vanaprastha': ['वानप्रस्थ'],
    'grihastha': ['गृहस्थ'],
    'brahmachari': ['ब्रह्मचारी'],
    
    // Common Hindi words in English
    'bachpan': ['बचपन'],
    'childhood': ['बचपन'],
    'jevan': ['जीवन'],
    'life': ['जीवन'],
    'prem': ['प्रेम'],
    'love': ['प्रेम'],
    'khushi': ['खुशी'],
    'happiness': ['खुशी'],
    'dukh': ['दुख'],
    'sorrow': ['दुख'],
    'mann': ['मन'],
    'mind': ['मन'],
    'hriday': ['हृदय'],
    'heart': ['हृदय'],
    'aasha': ['आशा'],
    'hope': ['आशा'],
    'vishwas': ['विश्वास'],
    'faith': ['विश्वास'],
    'shraddha': ['श्रद्धा'],
    'devotion': ['श्रद्धा'],
    'samay': ['समय'],
    'time': ['समय'],
    'kaal': ['काल'],
    'jagat': ['जगत'],
    'world': ['जगत'],
    'sansar': ['संसार'],
    'universe': ['संसार'],
    'prakrati': ['प्रकृति'],
    'nature': ['प्रकृति'],
    'jal': ['जल'],
    'water': ['जल'],
    'agni': ['अग्नि'],
    'fire': ['अग्नि'],
    'vayu': ['वायु'],
    'air': ['वायु'],
    'akash': ['आकाश'],
    'sky': ['आकाश'],
    'prithvi': ['पृथ्वी'],
    'earth': ['पृथ्वी'],
    'surya': ['सूर्य'],
    'sun': ['सूर्य'],
    'chandra': ['चंद्र'],
    'moon': ['चंद्र'],
    'tara': ['तारा'],
    'star': ['तारा'],
  };

  /// Convert Hindi text to English transliteration
  static String hindiToEnglish(String hindiText) {
    String result = hindiText.toLowerCase();
    
    // First handle longer sequences (conjuncts and special combinations)
    final sortedKeys = _hindiToEnglish.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    for (String hindi in sortedKeys) {
      result = result.replaceAll(hindi, _hindiToEnglish[hindi] ?? hindi);
    }
    
    return result.trim();
  }

  /// Convert English text to possible Hindi variations for matching
  static List<String> englishToHindiVariations(String englishText) {
    List<String> variations = [];
    String input = englishText.toLowerCase().trim();
    
    // Check for direct word mappings first
    for (String englishWord in _englishToHindiPhonetic.keys) {
      if (input.contains(englishWord)) {
        List<String> hindiVariations = _englishToHindiPhonetic[englishWord] ?? [];
        for (String hindiVar in hindiVariations) {
          String variation = input.replaceAll(englishWord, hindiVar);
          variations.add(variation);
        }
      }
    }
    
    // If no direct mappings found, do character-by-character transliteration
    if (variations.isEmpty) {
      variations.add(_characterByCharacterTransliteration(input));
    }
    
    return variations;
  }

  /// Perform character-by-character transliteration
  static String _characterByCharacterTransliteration(String input) {
    String result = input;
    
    // Sort by length to handle longer patterns first
    final sortedKeys = _englishToHindiPhonetic.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    for (String english in sortedKeys) {
      if (_englishToHindiPhonetic[english]?.isNotEmpty == true) {
        String hindi = _englishToHindiPhonetic[english]!.first;
        result = result.replaceAll(english, hindi);
      }
    }
    
    return result;
  }

  /// Enhanced search matching that works with both Hindi and English
  static bool matchesSearch(String text, String searchQuery) {
    if (searchQuery.trim().isEmpty) return true;
    
    String normalizedText = text.toLowerCase().trim();
    String normalizedQuery = searchQuery.toLowerCase().trim();
    
    // Direct match
    if (normalizedText.contains(normalizedQuery)) {
      return true;
    }
    
    // Convert Hindi text to English and check
    String textInEnglish = hindiToEnglish(normalizedText);
    if (textInEnglish.contains(normalizedQuery)) {
      return true;
    }
    
    // Convert English query to Hindi variations and check
    List<String> hindiVariations = englishToHindiVariations(normalizedQuery);
    for (String variation in hindiVariations) {
      if (normalizedText.contains(variation)) {
        return true;
      }
    }
    
    // Try partial matches for each word in the query
    List<String> queryWords = normalizedQuery.split(' ').where((w) => w.isNotEmpty).toList();
    List<String> textWords = normalizedText.split(' ').where((w) => w.isNotEmpty).toList();
    
    for (String queryWord in queryWords) {
      bool wordFound = false;
      
      // Check direct word match
      for (String textWord in textWords) {
        if (textWord.contains(queryWord)) {
          wordFound = true;
          break;
        }
        
        // Check transliterated match
        String textWordInEnglish = hindiToEnglish(textWord);
        if (textWordInEnglish.contains(queryWord)) {
          wordFound = true;
          break;
        }
      }
      
      // Check if English query word matches any Hindi text word
      if (!wordFound) {
        List<String> queryWordVariations = englishToHindiVariations(queryWord);
        for (String variation in queryWordVariations) {
          for (String textWord in textWords) {
            if (textWord.contains(variation)) {
              wordFound = true;
              break;
            }
          }
          if (wordFound) break;
        }
      }
      
      // If any word doesn't match, the whole query doesn't match
      if (!wordFound) {
        return false;
      }
    }
    
    return queryWords.isNotEmpty; // Return true if all words matched
  }

  /// Get search suggestions based on input
  static List<String> getSearchSuggestions(String input, List<String> allTitles) {
    if (input.trim().isEmpty) return [];
    
    List<String> suggestions = [];
    String normalizedInput = input.toLowerCase().trim();
    
    for (String title in allTitles) {
      if (matchesSearch(title, normalizedInput)) {
        suggestions.add(title);
      }
    }
    
    // Sort by relevance (exact matches first, then partial matches)
    suggestions.sort((a, b) {
      String aNorm = a.toLowerCase();
      String bNorm = b.toLowerCase();
      
      bool aExact = aNorm.contains(normalizedInput);
      bool bExact = bNorm.contains(normalizedInput);
      
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      
      return a.length.compareTo(b.length); // Prefer shorter titles
    });
    
    return suggestions.take(10).toList(); // Limit to 10 suggestions
  }
}
