import 'package:matrix/matrix.dart';

class SearchResultFormatter {
  String? _searchTerm = "";
  RegExp? _searchExp;

  SearchResultFormatter({String? searchTerm}) {
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
    text = text.replaceAllMapped(
      _searchExp!,
      (match) => "<b><i>${match[0]}</i></b>",
    );

    return text;
  }

  /* If event text contains a citation, remove it */
  String getTextWithoutCitation(Event event) {
    final text = event.formattedText;

    if (text.isEmpty) {
      return event.text;
    } else {
      return text.replaceAll(
        RegExp(
          '<mx-reply>.*</mx-reply>',
          caseSensitive: false,
          multiLine: false,
          dotAll: true,
        ),
        '',
      );
    }
  }
}
