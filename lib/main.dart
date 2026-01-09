import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'My_First_Flutter_App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

// MyAppState define os dados necessários para o app funcionar
class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var favorites = <WordPair>[];
  var history = <WordPair>[];

  GlobalKey? historyListKey;

  // ↓ Add this.
  void getNext() {
    manageHistory(current); // Adiciona a palavra anterior ao vetor
    current = WordPair.random();
    notifyListeners();
  }

  void manageHistory(WordPair? word) {
    word = word ?? current;
    /*if (history.length > 5){
      history.remove(history.last); // Remove a primeira palavra do histórico se encher demais
      notifyListeners();
    }*/
    history.insert(0, word);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
  }

  void toggleFavorite([WordPair? pair]) {
    pair = pair ?? current;
    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }

  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners(); // Atualiza a UI para remover o favorito e não causar erro
  }

  void removeHistory(WordPair pair) {
    history.remove(pair);
    // WIP !!!!!!!
    notifyListeners(); // Atualiza a UI para remover o favorito e não causar erro
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  var selectedIndex = 0;     // ← Add this property.

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        //page = Placeholder();
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,  // ← Here.
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
                    ),
                  ],
                  selectedIndex: selectedIndex,    // ← Change to this.
                  onDestinationSelected: (value) {
        
                    // ↓ Replace print with this.
                    setState(() {
                      selectedIndex = value;
                    });
        
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,  // ← Here.
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;                 // ← Add this.

    // ↓ Add this.
    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,  // ← Add this.
        children: [
          Expanded(
            flex: 3,
            child: HistoryListView(),
          ),
          SizedBox(height: 10),
          Text('A random AWESOME idea:'),
          //Text(appState.current.asLowerCase),   // ← Change this...
          BigCard(pair: pair),                // ← ... to this, creating a separate widget that doesn't interact with the whole state
          SizedBox(height: 10), // O widget SizedBox só ocupa espaço e não renderiza nada, usado para criar "lacunas" visuais.
          // ↓ Add this.
          Row(
            mainAxisSize: MainAxisSize.min,   // ← Add this.
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  print('button LIKE pressed!');
                  appState.toggleFavorite();  // ← This instead of print().
                },
                //child: Text('❤ Like'),
                icon: Icon(icon),
                label: Text('Like'),
              ),
              ElevatedButton(
                onPressed: () {
                  print('button NEXT pressed!');
                  appState.getNext();  // ← This instead of print().
                },
                child: Text('Next'),
              ),
            ],
          ),
          Spacer(flex: 2),      
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);       // ← Add this.
    // ↓ Add this.
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,    // ← And also this.
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        // ↓ Change this line.
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}

class HistoryListView extends StatefulWidget {
  const HistoryListView({Key? key}) : super(key: key);

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
  /// Needed so that [MyAppState] can tell [AnimatedList] below to animate
  /// new items.
  final _key = GlobalKey();

  /// Used to "fade out" the history items at the top, to suggest continuation.
  static const Gradient _maskingGradient = LinearGradient(
    // This gradient goes from fully transparent to fully opaque black...
    colors: [Colors.transparent, Colors.black],
    // ... from the top (transparent) to half (0.5) of the way to the bottom.
    stops: [0.0, 0.8],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      // This blend mode takes the opacity of the shader (i.e. our gradient)
      // and applies it to the destination (i.e. our animated list).
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: true,
        padding: EdgeInsets.only(top: 100),
        initialItemCount: appState.history.length,
        itemBuilder: (context, index, animation) {
          final pair = appState.history[index];
          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: ListTile(
                leading: IconButton(icon: Icon(appState.favorites.contains(pair) ? Icons.favorite : Icons.favorite_border, size: 12), //SizedBox(), // Se deixar SizedBox, fica sem ícone até favoritar
                          onPressed: () {
                            appState.toggleFavorite(pair);
                            print("$pair pressed!");
                          }),
                title: Text(
                  pair.asLowerCase,
                  semanticsLabel: pair.asPascalCase,
                ),
                trailing: IconButton(
                        icon:const Icon(Icons.delete_outline, semanticLabel: 'Delete'), 
                        onPressed: () { 
                          print("DeleteHistory function hasn't been implemented yet. Heavily WIP!");
                          showAlertDialog(context);
                          //appState.removeHistory(pair);
                        }),
              ),
            ),
          );
        },
      ),
    );
  }
}


// ...

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(30),
          child: Text(appState.favorites.length == 1 ? 'You have '
              '${appState.favorites.length} favorite:' : 'You have '
              '${appState.favorites.length} favorites:'),
        ),
        Expanded(
          // Make better use of wide windows with a grid.
          child: GridView(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 400 / 80,
            ),
            children: [
              for (var pair in appState.favorites)
                ListTile(
                  leading: Icon(Icons.favorite, color: theme.colorScheme.primary),
                  trailing: IconButton(
                        icon:const Icon(Icons.delete_outline, semanticLabel: 'Delete'), 
                        onPressed: () { 
                          appState.removeFavorite(pair); 
                        }),
                  title: Text(
                    pair.asLowerCase,
                    semanticsLabel: pair.asPascalCase,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------ Alerta -----------------------

showAlertDialog(BuildContext context) {

  // set up the button
  Widget okButton = TextButton(
    child: Text("OK"),
    onPressed: () { 
      Navigator.of(context).pop();
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("My title"),
    content: Text("This is my message."),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
