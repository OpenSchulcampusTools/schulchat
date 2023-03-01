import 'package:matrix/matrix.dart';

class SearchResultFormatter {
  String? _searchTerm = "";
  RegExp? _searchExp;

  SearchResultFormatter(String? searchTerm) {
    _searchTerm = searchTerm;
    if (isSearchResult()) {
      _searchExp = RegExp(searchTerm!, caseSensitive: false);
    }
  }

  bool isSearchResult() {
    return _searchTerm != null && _searchTerm!.isNotEmpty;
  }

  String getEventTextFormatted(Event event) {
    var text = event.formattedText;
    if (isSearchResult()) {
      // search result messages may not be a formatted-messages originally
      // -> take normal text in this case
      if (text.isEmpty) {
        text = event.text;
      }

      return _replaceSearchResults(text);
    } else {
      return text;
    }
  }

  String _replaceSearchResults(String text) {
    //   final startIndex = _getStartIndex(text);
    text = text.replaceAllMapped(
        _searchExp!, (match) => "<b><i>${match[0]}</i></b>");

    return text;
  }

/*int _getStartIndex(String text) {
    const replyEndText = "</mx-reply>";
    final replyIndex = text.indexOf(replyEndText);

    if(replyIndex < 0) {
      return 0;
    }
    else {
      // if text contains a replay start after reply
      return replyIndex+replyEndText.length;
    }
  }
   */
}
