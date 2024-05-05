/*this class represents the state of the application.
it includes the library, a list of the opened tabs, the current tab, the current view, 
and the some other app settings like dark mode and the seed color*/

import 'dart:math';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:flutter/material.dart';
import 'package:otzaria/data/data.dart';
import 'package:otzaria/data/file_system_data_provider.dart';
import 'package:otzaria/models/bookmark.dart';
import 'package:otzaria/models/library.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/models/books.dart';
import 'package:hive/hive.dart';

/// Represents the state of the application.
///
/// It includes the library, a list of the opened tabs, the current tab,
/// the current view, and the some other app settings like dark mode and
/// the seed color.
class AppModel with ChangeNotifier {
  /// The data provider for the application.
  Data data = FileSystemData.instance;

  /// The library of books.
  late Library library;

  /// The list of opened tabs.
  List<OpenedTab> tabs = [];

  /// The index of the current tab.
  int currentTab = 0;

  /// The index of the current view.
  int _currentView = 0;

  int get currentView => _currentView;

  set currentView(int i) {
    _currentView = i;
    notifyListeners();
  }

  final List<dynamic> rawBookmarks =
      Hive.box(name: 'bookmarks').get('key-bookmarks') ?? [];
  late List<Bookmark> bookmarks;

  /// Flag indicating if the app is in dark mode.
  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(
    Settings.getValue<bool>('key-dark-mode') ?? false,
  );

  /// The color used as seed.
  final ValueNotifier<Color> seedColor = ValueNotifier<Color>(
    ConversionUtils.colorFromString(
        Settings.getValue<String>('key-swatch-color') ?? ('#ff2c1b02')),
  );

  /// a focus node for the search field in libraryBrowser
  FocusNode bookLocatorFocusNode = FocusNode();

  /// Constructs a new AppModel instance.
  ///
  /// This constructor initializes the library and tabs list, and loads the
  /// tabs list from disk.
  AppModel() {
    library = data.getLibrary();

    tabs = List<OpenedTab>.from(
        ((Hive.box(name: 'tabs').get('key-tabs') ?? []) as List)
            .map((e) => OpenedTab.fromJson(e))
            .toList());

    currentTab = Hive.box(name: 'tabs')
        .get('key-current-tab', defaultValue: tabs.length - 1);

    bookmarks = rawBookmarks.map((e) => Bookmark.fromJson(e)).toList();

    seedColor.addListener(() {
      notifyListeners();
    });
    isDarkMode.addListener(() {
      notifyListeners();
    });
  }

  /// Opens a book in a new tab.
  ///
  /// [book] The book to open.
  /// [index] The index of the book.
  void openBook(Book book, int index) {
    if (book is PdfBook) {
      addTab(PdfBookTab(book, index));
    } else if (book is TextBook) {
      addTab(TextBookTab(book: book, initalIndex: index));
    }
  }

  void openNewSearchTab() {
    addTab(SearchingTab('חיפוש'));
  }

  /// Adds a new tab to the list of opened tabs.
  ///
  /// [tab] The tab to add.
  void addTab(OpenedTab tab) {
    //add the tab after the current tab, or at the end if this is the last tab
    tabs.insert(min(currentTab + 1, tabs.length), tab);
    //opdate the current tab, while making sure it is not goes beyond the list.
    currentTab = min(currentTab + 1, tabs.length - 1);
    notifyListeners();
    saveTabsToDisk();
  }

  /// Closes a tab.
  ///
  /// [tab] The tab to close.
  void closeTab(OpenedTab tab) {
    tabs.remove(tab);
    notifyListeners();
    saveTabsToDisk();
  }

  void closeCurrentTab() {
    closeTab(tabs[currentTab]);
  }

  /// Closes all tabs.
  void closeAllTabs() {
    tabs = [];
    currentTab = 0;
    notifyListeners();
    saveTabsToDisk();
  }

  /// Saves the list of tabs and  the current tab index to disk.
  void saveTabsToDisk() {
    Hive.box(name: 'tabs').put("key-tabs", tabs);
    Hive.box(name: 'tabs').put("key-current-tab", currentTab);
  }

  void addBookmark(
      {required String ref, required String title, required int index}) {
    bookmarks.add(Bookmark(ref: ref, title: title, index: index));
    // write to disk
    Hive.box(name: 'bookmarks').put('key-bookmarks', bookmarks);
  }

  void removeBookmark(int index) {
    bookmarks.removeAt(index);
    Hive.box(name: 'bookmarks').put('key-bookmarks', bookmarks);
  }

  void clearBookmarks() {
    bookmarks.clear();
    Hive.box(name: 'bookmarks').clear();
  }
}
