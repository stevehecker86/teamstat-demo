// TeamStat Demo (vereinfacht, ohne Position + Trefferquote in Auswertung)
// Kopieren nach https://dartpad.dev/flutter

import 'package:flutter/material.dart';

void main() {
  runApp(TeamStatDemo());
}

class TeamStatDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeamStat Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PlayerListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Player {
  final int id;
  final String name;
  final int number;
  Player({required this.id, required this.name, required this.number});
}

class PlayerStat {
  final int playerId;
  String gameName;
  int passCompleted;
  int passFailed;
  int shots;
  int goals;
  int assists;
  PlayerStat({
    required this.playerId,
    required this.gameName,
    this.passCompleted = 0,
    this.passFailed = 0,
    this.shots = 0,
    this.goals = 0,
    this.assists = 0,
  });
}

class MemoryStore {
  int _nextPlayerId = 1;
  final List<Player> players = [];
  final Map<String, List<PlayerStat>> games = {};

  int addPlayer(String name, int number) {
    final id = _nextPlayerId++;
    players.add(Player(id: id, name: name, number: number));
    return id;
  }

  void saveGame(String gameName, List<PlayerStat> stats) {
    games[gameName] = stats.map((s) => PlayerStat(
      playerId: s.playerId,
      gameName: s.gameName,
      passCompleted: s.passCompleted,
      passFailed: s.passFailed,
      shots: s.shots,
      goals: s.goals,
      assists: s.assists,
    )).toList();
  }
}

final store = MemoryStore();

/* ------------------------- Spielerübersicht ------------------------- */
class PlayerListPage extends StatefulWidget {
  @override
  _PlayerListPageState createState() => _PlayerListPageState();
}

class _PlayerListPageState extends State<PlayerListPage> {
  void _openAddPlayer() async {
    await showDialog(context: context, builder: (_) => AddPlayerDialog());
    setState(() {});
  }

  void _startMatch() {
    if (store.players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Füge zuerst Spieler hinzu.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MatchPage()));
  }

  void _openSavedGames() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SavedGamesPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TeamStat Demo'),
        actions: [
          IconButton(icon: Icon(Icons.history), onPressed: _openSavedGames),
          IconButton(icon: Icon(Icons.play_arrow), onPressed: _startMatch),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: store.players.isEmpty
            ? Center(child: Text('Noch keine Spieler.\nDrücke + um Spieler hinzuzufügen.', textAlign: TextAlign.center))
            : ListView.builder(
                itemCount: store.players.length,
                itemBuilder: (context, i) {
                  final p = store.players[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(p.number.toString())),
                      title: Text(p.name),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() {
                            store.players.removeAt(i);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPlayer,
        label: Text('Spieler +'),
        icon: Icon(Icons.add),
      ),
    );
  }
}

/* ------------------------- Spieler hinzufügen ------------------------- */
class AddPlayerDialog extends StatefulWidget {
  @override
  _AddPlayerDialogState createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<AddPlayerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _numC = TextEditingController();

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameC.text.trim();
    final number = int.tryParse(_numC.text.trim()) ?? 0;
    store.addPlayer(name, number);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Spieler hinzufügen'),
      content: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: _nameC, decoration: InputDecoration(labelText: 'Name'), validator: (v) => v == null || v.isEmpty ? 'Bitte Name' : null),
          TextFormField(controller: _numC, decoration: InputDecoration(labelText: 'Rückennummer'), keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Bitte Nummer' : null),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Abbrechen')),
        ElevatedButton(onPressed: _save, child: Text('Speichern')),
      ],
    );
  }
}

/* ------------------------- Live-Erfassung ------------------------- */
class MatchPage extends StatefulWidget {
  @override
  _MatchPageState createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  String gameName = '';
  late Map<int, PlayerStat> liveStats;

  @override
  void initState() {
    super.initState();
    liveStats = {for (var p in store.players) p.id: PlayerStat(playerId: p.id, gameName: '')};
  }

  void _saveGame() {
    if (gameName.trim().isEmpty) {
      gameName = 'Spiel ${DateTime.now().toLocal()}';
    }
    for (var s in liveStats.values) s.gameName = gameName;
    store.saveGame(gameName, liveStats.values.toList());
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => PostGamePage(gameName: gameName)));
  }

  Widget _button(IconData icon, String label, Color color, VoidCallback onTap, int value) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text('$label ($value)'),
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final players = store.players;
    return Scaffold(
      appBar: AppBar(title: Text('Live-Erfassung')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(labelText: 'Spielname (optional)', border: OutlineInputBorder()),
              onChanged: (v) => gameName = v,
            ),
          ),
          ...players.map((p) {
            final s = liveStats[p.id]!;
            return Card(
              margin: EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${p.number} - ${p.name}', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(spacing: 8, children: [
                      _button(Icons.check, 'Pass +', Colors.green, () => setState(() => s.passCompleted++), s.passCompleted),
                      _button(Icons.close, 'Fehlpass +', Colors.red, () => setState(() => s.passFailed++), s.passFailed),
                      _button(Icons.sports_soccer, 'Schuss +', Colors.orange, () => setState(() => s.shots++), s.shots),
                      _button(Icons.star, 'Tor +', Colors.blue, () => setState(() => s.goals++), s.goals),
                      _button(Icons.assistant, 'Vorlage +', Colors.purple, () => setState(() => s.assists++), s.assists),
                    ])
                  ],
                ),
              ),
            );
          }).toList(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text('Speichern & Auswertung'),
              onPressed: _saveGame,
            ),
          )
        ],
      ),
    );
  }
}

/* ------------------------- Auswertung ------------------------- */
class PostGamePage extends StatelessWidget {
  final String gameName;
  PostGamePage({required this.gameName});

  @override
  Widget build(BuildContext context) {
    final stats = store.games[gameName] ?? [];
    final players = {for (var p in store.players) p.id: p};

    return Scaffold(
      appBar: AppBar(title: Text('Auswertung')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Nr')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Passquote')),
            DataColumn(label: Text('Schüsse')),
            DataColumn(label: Text('Tore')),
            DataColumn(label: Text('Trefferquote')),
            DataColumn(label: Text('Vorlagen')),
          ],
          rows: stats.map((s) {
            final p = players[s.playerId];
            final totalPass = s.passCompleted + s.passFailed;
            final passPct = totalPass == 0 ? '-' : '${(s.passCompleted / totalPass * 100).round()}%';
            final hitPct = s.shots == 0 ? '-' : '${(s.goals / s.shots * 100).round()}%';
            return DataRow(cells: [
              DataCell(Text(p?.number.toString() ?? '')),
              DataCell(Text(p?.name ?? '')),
              DataCell(Text(passPct)),
              DataCell(Text('${s.shots}')),
              DataCell(Text('${s.goals}')),
              DataCell(Text(hitPct)),
              DataCell(Text('${s.assists}')),
            ]);
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.home),
        onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => PlayerListPage())),
      ),
    );
  }
}

/* ------------------------- Gespeicherte Spiele ------------------------- */
class SavedGamesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final games = store.games.keys.toList();
    return Scaffold(
      appBar: AppBar(title: Text('Gespeicherte Spiele')),
      body: games.isEmpty
          ? Center(child: Text('Keine gespeicherten Spiele'))
          : ListView.builder(
              itemCount: games.length,
              itemBuilder: (context, i) {
                final g = games[i];
                final stats = store.games[g] ?? [];
                final totalGoals = stats.fold(0, (sum, s) => sum + s.goals);
                return ListTile(
                  title: Text(g),
                  subtitle: Text('${stats.length} Spieler, Tore: $totalGoals'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostGamePage(gameName: g))),
                );
              },
            ),
    );
  }
}
