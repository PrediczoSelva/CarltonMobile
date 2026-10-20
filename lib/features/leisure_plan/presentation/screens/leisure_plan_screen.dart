

import 'package:flutter/material.dart';

import 'leisure_package_detail_screen.dart';


const kNavy = Color(0xFF002B49);
const kBlue = Color(0xFF1E3A8A);
const kYellow = Color(0xFFF5B301);
const kBg = Color(0xFFF5F7FB);
const kPeach = Color(0xFFFDF1E0);


class LeisurePackage {
  final String title, country, tag, duration, price, save;
  final String? oldPrice, imageUrl, imageAsset;
  final List<String> highlights;
  const LeisurePackage({
    required this.title,
    required this.country,
    required this.tag,
    required this.duration,
    required this.price,
    this.save = '',
    this.oldPrice,
    this.imageUrl,
    this.imageAsset,
    this.highlights = const [],
  });
}

const _packages = <LeisurePackage>[
  LeisurePackage(
    title: 'Srilankan Hill Country saga',
    country: 'Sri Lanka',
    tag: 'Beach & Island',
    duration: '1 Nights / 2 Days',
    price: '0',
    save: 'SAVE 20%',
    highlights: ['Hiking', 'Yoga', 'Fitness', 'Adventure', 'Nightlife', 'Hills'],
  ),
  LeisurePackage(
    title: 'Turkey Escape',
    country: 'Turkey',
    imageAsset: 'assets/images/turkey.jpg',
    tag: 'Popular',
    duration: '8 Nights',
    price: '1550',
    oldPrice: '2000',
    save: 'SAVE 22%',
  ),
  LeisurePackage(
    title: 'Bangkok & Colombo Getaway',
    country: 'Thailand + Sri Lanka',
    imageAsset: 'assets/images/thailand.jpg',
    tag: 'Family Favorite',
    duration: '16 Nights',
    price: '5580',
  ),
  LeisurePackage(
    title: 'Maldives Bliss Escape',
    country: 'Maldives',
    imageAsset: 'assets/images/maldives_hero.jpg',
    tag: 'Limited Spots',
    duration: '6 Nights',
    price: '120',
    oldPrice: '150',
    save: '20%',
    highlights: ['Flights', 'All Inclusive', 'Overwater Villa'],
  ),
];


class LeisurePlanPage extends StatefulWidget {
  const LeisurePlanPage({super.key});

  @override
  State<LeisurePlanPage> createState() => _LeisurePlanPageState();
}

class _LeisurePlanPageState extends State<LeisurePlanPage> {
  int _tab = 0;
  static const _tabs = ['Confirmed', 'Pending', 'Past', 'Cancelled'];
  static const _counts = [0, 0, 0, 1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kNavy,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Leisure Plan', style: TextStyle(fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Plan your journey, book automatically at the best price.',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
            children: const [
              _StatCard('TOTAL PLANS', '1', Icons.calendar_today_outlined,
                  Color(0xFFE3ECFF)),
              _StatCard('BOOKED', '0', Icons.check_circle_outline,
                  Color(0xFFE3F1FF)),
              _StatCard('TOTAL SAVED', '0', Icons.shield_outlined,
                  Color(0xFFFFF0DC)),
              _StatCard('PENDING BOOKINGS', '0', Icons.access_time,
                  Color(0xFFE8EEFF)),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CreateLeisurePlanPage())),
              child: const Text('Add New',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: kBlue, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Featured Packages',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: kBlue)),
                        Text('Hand-picked deals for your next getaway',
                            style:
                            TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  TextButton(
                      style: TextButton.styleFrom(minimumSize: const Size(0, 40)),
                      onPressed: () {},
                      child: const Text('View All →')),
                ]),
                const SizedBox(height: 12),
                for (final p in _packages) _PackageCard(p),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Customized Plans',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: kBlue)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: InkWell(
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: _tab == i ? kBlue : Colors.transparent,
                                width: 2),
                          ),
                        ),
                        child: Row(children: [
                          Text(_tabs[i],
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _tab == i ? kBlue : Colors.grey)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: _tab == i ? kBlue : Colors.transparent,
                                borderRadius: BorderRadius.circular(10)),
                            child: Text('${_counts[i]}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                    _tab == i ? Colors.white : Colors.grey)),
                          ),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE8EEFF),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.inbox_outlined, color: kBlue),
                  ),
                  const SizedBox(height: 12),
                  Text('No ${_tabs[_tab].toLowerCase()} plans found',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Create a new leisure plan to get started.',
                      style: TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: kBlue, foregroundColor: Colors.white),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CreateLeisurePlanPage())),
                    child: const Text('Create Plan'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _card({required Widget child, EdgeInsets? padding}) => Container(
  padding: padding ?? const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))
    ],
  ),
  child: child,
);

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color tint;
  const _StatCard(this.label, this.value, this.icon, this.tint);

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: kBlue)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: kBlue)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration:
            BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: kBlue),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final LeisurePackage p;
  const _PackageCard(this.p);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (p.imageAsset != null)
                  Image.asset(p.imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                else if (p.imageUrl != null)
                  Image.network(p.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                else
                  _placeholder(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                ),
                Positioned(
                    top: 10, left: 10, child: _pill(p.country, kBlue, Colors.white,
                    icon: Icons.location_on_outlined)),
                Positioned(
                    top: 10,
                    right: 10,
                    child: _pill(p.tag, const Color(0xFFFFD79A), const Color(0xFF9A5B00))),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(p.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700)),
                      ),
                      _pill(p.duration, Colors.black54, Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.highlights.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final h in p.highlights)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('✓ $h',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black54)),
                        ),
                    ],
                  ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.oldPrice != null)
                            Text(p.oldPrice!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough)),
                          Text(p.price,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: kBlue)),
                          if (p.save.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: kPeach,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text(p.save,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF9A5B00))),
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: kBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => PackageDetailPage(package: p))),
                      child: const Text('Book Now →'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
          colors: [Color(0xFF3B6BA5), Color(0xFF9CC3E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
    ),
  );

  Widget _pill(String t, Color bg, Color fg, {IconData? icon}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration:
    BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 3)],
      Text(t,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    ]),
  );
}


class CreateLeisurePlanPage extends StatefulWidget {
  const CreateLeisurePlanPage({super.key});

  @override
  State<CreateLeisurePlanPage> createState() => _CreateLeisurePlanPageState();
}

class _CreateLeisurePlanPageState extends State<CreateLeisurePlanPage> {

  final List<TextEditingController> _country = [TextEditingController()];
  final List<TextEditingController> _days = [TextEditingController()];


  final _travelers = <String, String>{
    'Alice Johnson': 'United States • Adult',
    'Sanduni Alisandirisge': 'Sri Lanka • Adult',
  };
  final Set<String> _selectedTravelers = {};


  String _budgetType = 'Maximum';
  String _currency = 'USD';
  double _budget = 220;

  final Set<String> _transport = {};
  final Set<String> _experiences = {};
  final Set<String> _special = {};
  String? _meal;
  bool _excludeVisited = false;

  final Map<String, int> _rooms = {
    'Single Room': 0,
    'Twin Room': 0,
    'Double Room': 0,
    'Triple Room': 0,
    'Family Room': 0,
    'Suite': 0,
    'Dormitory': 0,
  };
  static const _roomSub = {
    'Single Room': '1 Person',
    'Twin Room': '2 Single Beds',
    'Double Room': '2 People',
    'Triple Room': '3 People',
    'Family Room': '2 Adults + Up to 2 children',
    'Suite': '1-2 People',
    'Dormitory': '1 Person Shared Room',
  };

  DateTime? _from, _to;
  final _notes = TextEditingController();

  @override
  void dispose() {
    for (final c in [..._country, ..._days, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(bool from) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (d != null) setState(() => from ? _from = d : _to = d);
  }

  String _fmt(DateTime? d) => d == null
      ? 'mm/dd/yyyy'
      : '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  void _submit() {
    if (_selectedTravelers.isEmpty) {
      _snack('Select at least one saved traveler to generate your leisure plan.');
      return;
    }
    if (_country.any((c) => c.text.trim().isEmpty) ||
        _days.any((c) => c.text.trim().isEmpty)) {
      _snack('Please fill destination and total days.');
      return;
    }
    if (_from == null || _to == null) {
      _snack('Please select from and to dates.');
      return;
    }

    _snack('Leisure plan request ready to submit');
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kNavy,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Create Leisure Plan', style: TextStyle(fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _section('Destinations', [
            for (var i = 0; i < _country.length; i++) ...[
              Text('Destination ${i + 1}',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              _field(_country[i], 'Country / City *'),
              const SizedBox(height: 10),
              _field(_days[i], 'Total Days *', number: true),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => setState(() {
                  _country.add(TextEditingController());
                  _days.add(TextEditingController());
                }),
                child: const Text('+ Add Destination'),
              ),
            ),
          ]),

          _section('Select Travelers', [
            for (final e in _travelers.entries)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _selectedTravelers.contains(e.key),
                onChanged: (v) => setState(() => v == true
                    ? _selectedTravelers.add(e.key)
                    : _selectedTravelers.remove(e.key)),
                title: Text(e.key,
                    style: const TextStyle(
                        color: kBlue, fontWeight: FontWeight.w600)),
                subtitle: Text(e.value, style: const TextStyle(fontSize: 12)),
              ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () {

              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add New Traveler'),
            ),
            if (_selectedTravelers.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                    'Select at least one saved traveler to generate your leisure plan.',
                    style: TextStyle(color: Colors.orange, fontSize: 12)),
              ),
          ]),

          _section('Budget', [
            Row(children: [
              Expanded(
                  child: _dropdown('Budget Type', _budgetType,
                      ['Maximum', 'Minimum', 'Exact'],
                          (v) => setState(() => _budgetType = v!))),
              const SizedBox(width: 12),
              Expanded(
                  child: _dropdown('Currency', _currency,
                      ['USD', 'LKR', 'EUR', 'GBP'],
                          (v) => setState(() => _currency = v!))),
            ]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_budgetType Budget',
                    style: const TextStyle(color: Colors.black54)),
                Text('\$ ${_budget.round()}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            Slider(
              value: _budget,
              min: 0,
              max: 10000,
              activeColor: kBlue,
              onChanged: (v) => setState(() => _budget = v),
            ),
          ]),

          _section('Past Destinations', [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _excludeVisited,
              onChanged: (v) => setState(() => _excludeVisited = v),
              title: const Text('Exclude all visited places',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Or pick specific destinations below to include or replace.'),
            ),
            const Text('Select travelers to see your past destinations.',
                style: TextStyle(color: Colors.black45, fontSize: 12)),
          ]),

          _section('Passengers', [
            _countRow('Adults', '12+', _selectedTravelers.length),
            _countRow('Children', 'Age 2–11', 0),
            _countRow('Infants', 'Under 2', 0),
            const Text('Counts are derived from selected traveler profiles.',
                style: TextStyle(color: Colors.black45, fontSize: 12)),
          ]),
          _section('Local Transportation', [
            _chips(const [
              'Private Van', 'Private Taxi', 'Shared Shuttle', 'Public Transit',
              'Rental Car', 'Motorbike Rental', 'Airport Transit', 'Tuk-tuk/local'
            ], _transport),
          ]),
          _section('Experiences', [
            _chips(const [
              'Beach & Swim', 'Beauty & grooming', 'Yoga retreats',
              'Food & Dining', 'Nature & hiking', 'Spa & massage',
              'Culture & History', 'Night Life', 'Adventure Sports',
              'Safari & Wildlife', 'Cruise', 'Shopping', 'Fitness & gym'
            ], _experiences),
          ]),
          _section('Special Requirements', [
            _chips(const [
              'Wheel Chair access', 'Hearing Assistance', 'Visual impairment aid',
              'Traveling with Pet', 'Dietary Restrictions', 'Infant Bassinet',
              'Medical Equipment', 'Extra Legroom Seats'
            ], _special),
            const SizedBox(height: 12),
            const Text('Additional Notes',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _notes,
              maxLines: 4,
              decoration: _dec('Any other special needs or requests…'),
            ),
          ]),
          _section('Room Preferences', [
            for (final r in _rooms.keys)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: kPeach, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r,
                            style:
                            const TextStyle(fontWeight: FontWeight.w700)),
                        Text(_roomSub[r]!,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                  _stepper(
                    _rooms[r]!,
                        () => setState(() => _rooms[r] = (_rooms[r]! - 1).clamp(0, 20)),
                        () => setState(() => _rooms[r] = (_rooms[r]! + 1).clamp(0, 20)),
                  ),
                ]),
              ),
          ]),
          _section('Meal Preferences', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in const [
                  'No Preference', 'Bed & Breakfast', 'All Inclusive',
                  'Vegetarian', 'Half Board', 'Vegan', 'Full Board', 'Halal',
                  'Pescatarian', 'Eggetarian', 'Spicy', 'Mild'
                ])
                  ChoiceChip(
                    label: Text(m, style: const TextStyle(fontSize: 12)),
                    selected: _meal == m,
                    selectedColor: kBlue.withOpacity(.15),
                    onSelected: (_) => setState(() => _meal = m),
                  ),
              ],
            ),
          ]),
          _section('Date Range', [
            Row(children: [
              Expanded(child: _dateBox('From Date *', _from, () => _pickDate(true))),
              const SizedBox(width: 12),
              Expanded(child: _dateBox('To Date *', _to, () => _pickDate(false))),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: kPeach, borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Selected Date Range [${_from == null ? 'dd/mm/yyyy' : _fmt(_from)} - ${_to == null ? 'dd/mm/yyyy' : _fmt(_to)}]',
                textAlign: TextAlign.center,
                style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _submit,
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('Create My Leisure Plan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }


  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: _card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F6FD),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kBlue)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children),
          ),
        ],
      ),
    ),
  );

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  Widget _field(TextEditingController c, String label, {bool number = false}) =>
      TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: _dec('').copyWith(labelText: label, hintText: null),
      );

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: _dec('').copyWith(labelText: label, hintText: null),
        items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i))],
        onChanged: onChanged,
      );

  Widget _chips(List<String> labels, Set<String> selected) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final l in labels)
        FilterChip(
          label: Text(l, style: const TextStyle(fontSize: 12)),
          selected: selected.contains(l),
          selectedColor: kBlue.withOpacity(.15),
          onSelected: (v) =>
              setState(() => v ? selected.add(l) : selected.remove(l)),
        ),
    ],
  );

  Widget _countRow(String t, String sub, int n) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(sub,
                style: const TextStyle(fontSize: 11, color: Colors.black45)),
          ],
        ),
      ),
      Text('$n', style: const TextStyle(fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _stepper(int v, VoidCallback minus, VoidCallback plus) => Row(
    children: [
      _sq(Icons.remove, minus),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('$v',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      _sq(Icons.add, plus),
    ],
  );

  Widget _sq(IconData i, VoidCallback f) => InkWell(
    onTap: f,
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFFBE3BE),
          borderRadius: BorderRadius.circular(6)),
      child: Icon(i, size: 16),
    ),
  );

  Widget _dateBox(String label, DateTime? d, VoidCallback onTap) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12)),
      const SizedBox(height: 6),
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 16),
            const SizedBox(width: 6),
            Expanded(
                child: Text(_fmt(d),
                    style: TextStyle(
                        fontSize: 13,
                        color: d == null ? Colors.black45 : Colors.black87))),
          ]),
        ),
      ),
    ],
  );
}
