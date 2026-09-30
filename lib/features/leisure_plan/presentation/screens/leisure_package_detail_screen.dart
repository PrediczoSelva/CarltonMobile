import 'package:flutter/material.dart';

import 'leisure_plan_screen.dart';


class PkgIncluded {
  final String title, desc;
  const PkgIncluded(this.title, this.desc);
}

class PkgDay {
  final String days, title, desc;
  const PkgDay(this.days, this.title, this.desc);
}

class PkgTier {
  final String name, desc;
  final double price;
  final bool popular;
  const PkgTier(this.name, this.price, this.desc, {this.popular = false});
}

class PackageDetail {
  final String tagline, experience;
  final int nights, rating;
  final double transferPerPerson;
  final List<PkgIncluded> included;
  final List<PkgDay> itinerary;
  final List<PkgTier> tiers;
  final List<String> gallery;
  final String reviewText, reviewer, reviewMeta;

  const PackageDetail({
    required this.tagline,
    required this.experience,
    required this.nights,
    required this.included,
    required this.itinerary,
    required this.tiers,
    this.rating = 5,
    this.transferPerPerson = 120,
    this.gallery = const [],
    this.reviewText = '',
    this.reviewer = '',
    this.reviewMeta = '',
  });


  factory PackageDetail.forPackage(LeisurePackage p) {
    final nights =
        int.tryParse(RegExp(r'\d+').firstMatch(p.duration)?.group(0) ?? '') ?? 1;

    if (p.title.toLowerCase().contains('maldives')) {
      return const PackageDetail(
        tagline:
        'Awaken to the gentle rhythm of the Indian Ocean in your private sanctuary.',
        experience:
        'Float above the turquoise Indian Ocean in your own overwater villa. Seven nights of pure calm.',
        nights: 6,
        included: [
          PkgIncluded('Return Flights', 'Business class flights from major hubs'),
          PkgIncluded('Overwater Villa', 'Platinum Villa with infinity pool'),
          PkgIncluded('All Inclusive Dining',
              'Gourmet meals across 5 specialty restaurants'),
          PkgIncluded('Guided Snorkelling', 'Professional Guided Tour'),
        ],
        itinerary: [
          PkgDay('Day 1', 'Arrival & Welcome', 'Speedboat transfer to resort.'),
          PkgDay('Day 2-3', 'Ocean & Reef', 'Morning snorkelling, dolphin cruise.'),
          PkgDay('Day 4-5', 'Island Hopping', 'Day trip to a local Maldivian island.'),
          PkgDay('Day 6', 'Leisure & Spa', 'Fully free day.'),
        ],
        tiers: [
          PkgTier('Standard', 2210, 'Garden-view villa, economy flight'),
          PkgTier('Premium', 3210, 'Garden-view villa, premium economy',
              popular: true),
          PkgTier('Luxury', 5210, 'Overwater villa, business class'),
        ],
        gallery: [
          'assets/images/maldives_gallery_1.jpg',
          'assets/images/maldives_gallery_2.jpg',
          'assets/images/maldives_gallery_3.jpg',
        ],
        reviewText: 'We celebrated our 10th anniversary here…',
        reviewer: 'Elena',
        reviewMeta: 'Stayed at Jul-2026',
      );
    }

    final base = double.tryParse(p.price) ?? 0;
    final std = base > 0 ? base : 1000.0;
    return PackageDetail(
      tagline: 'Discover ${p.title}.',
      experience:
      'Enjoy a ${p.duration.split('/').first.trim()} escape to ${p.country}, hand-picked for you.',
      nights: nights,
      included: const [
        PkgIncluded('Accommodation', 'Comfortable stay at a selected hotel'),
        PkgIncluded('Local Transfers', 'Airport and sightseeing transfers'),
        PkgIncluded('Daily Breakfast', 'Fresh breakfast every morning'),
        PkgIncluded('Guided Experiences', 'Professional guided tours'),
      ],
      itinerary: const [
        PkgDay('Day 1', 'Arrival & Welcome', 'Airport pickup and hotel check-in.'),
        PkgDay('Middle days', 'Explore', 'Sightseeing and local experiences.'),
        PkgDay('Last day', 'Departure', 'Check-out and transfer to the airport.'),
      ],
      tiers: [
        PkgTier('Standard', std, 'Standard room, economy flight'),
        PkgTier('Premium', (std * 1.45).roundToDouble(),
            'Superior room, premium economy',
            popular: true),
        PkgTier('Luxury', (std * 2.36).roundToDouble(),
            'Luxury suite, business class'),
      ],
      gallery: [if (p.imageAsset != null) p.imageAsset!],
    );
  }
}


class PackageDetailPage extends StatefulWidget {
  final LeisurePackage package;
  const PackageDetailPage({super.key, required this.package});

  @override
  State<PackageDetailPage> createState() => _PackageDetailPageState();
}

class _PackageDetailPageState extends State<PackageDetailPage> {
  late final PackageDetail d = PackageDetail.forPackage(widget.package);
  int _tier = 0;
  DateTime? _date;
  int _adults = 1, _children = 0, _infants = 0;

  int get _guests => _adults + _children + _infants;
  int get _payingGuests => _adults + _children; // infants travel free
  double get _perPerson => d.tiers[_tier].price;
  double get _total => _perPerson * _payingGuests;
  double get _transfers => d.transferPerPerson * _payingGuests;
  double get _accommodation => _total - _transfers;

  String _money(double v) =>
      '\$${v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

  String _fmtDate(DateTime? x) => x == null
      ? 'mm/dd/yyyy'
      : '${x.month.toString().padLeft(2, '0')}/${x.day.toString().padLeft(2, '0')}/${x.year}';

  Future<void> _pickDate() async {
    final x = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (x != null) setState(() => _date = x);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.package;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kNavy,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Package Details', style: TextStyle(fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _hero(p),
          _infoBar(p),
          _section('Experience',
              child: Text(d.experience,
                  style: const TextStyle(fontSize: 14, height: 1.5))),
          _includedCard(),
          _itinerary(),
          _bookingCard(),
          if (d.gallery.isNotEmpty) _gallery(),
          if (d.reviewText.isNotEmpty) _review(),
        ],
      ),
    );
  }


  Widget _hero(LeisurePackage p) => SizedBox(
    height: 250,
    child: Stack(
      fit: StackFit.expand,
      children: [
        _img(p.imageAsset ?? (d.gallery.isNotEmpty ? d.gallery.first : null)),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(p.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(d.tagline,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _infoBar(LeisurePackage p) {
    Widget item(IconData icon, String label, String value, [String? sub]) =>
        Expanded(
          child: Row(children: [
            Icon(icon, color: kBlue, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: .5,
                          fontWeight: FontWeight.w600,
                          color: kBlue)),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: kBlue)),
                  if (sub != null)
                    Text(sub,
                        style: const TextStyle(fontSize: 11, color: kBlue)),
                ],
              ),
            ),
          ]),
        );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kPeach, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(children: [
          item(Icons.access_time, 'DURATION', '${d.nights} Nights',
              _date == null ? 'Select Dates' : _fmtDate(_date)),
          item(Icons.location_on_outlined, 'LOCATION', p.country),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          item(Icons.people_outline, 'TRAVELERS',
              '$_adults Adult${_adults == 1 ? '' : 's'}'),
          item(Icons.star, 'RATING', '${d.rating}'),
        ]),
      ]),
    );
  }

  Widget _includedCard() => _section(
    "What's included",
    child: GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        for (final i in d.included)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPeach,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 6)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: kBlue,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(i.desc,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _itinerary() => _section(
    'Day by day itinerary',
    child: Column(
      children: [
        for (var i = 0; i < d.itinerary.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 22,
                  child: Column(children: [
                    const SizedBox(height: 4),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          color: kBlue, shape: BoxShape.circle),
                    ),
                    if (i != d.itinerary.length - 1)
                      Expanded(
                          child: Container(width: 1.5, color: Colors.black26)),
                  ]),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.itinerary[i].days,
                            style: const TextStyle(
                                color: kBlue, fontWeight: FontWeight.w600)),
                        Text(d.itinerary[i].title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(d.itinerary[i].desc,
                            style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _bookingCard() {
    final canBook = _date != null && _payingGuests > 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Your Tier',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: kBlue)),
          const SizedBox(height: 12),
          for (var i = 0; i < d.tiers.length; i++) _tierTile(i),
          const SizedBox(height: 8),
          const Text('Select Date',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.access_time, size: 18, color: Colors.black45),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_fmtDate(_date),
                        style: TextStyle(
                            color:
                            _date == null ? Colors.black45 : Colors.black87))),
                const Icon(Icons.calendar_today_outlined, size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Guests',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(10)),
                child: Text('$_guests Total',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _guestRow('Adults', '12+', _adults, min: 1,
                  onChanged: (v) => setState(() => _adults = v)),
              const Divider(height: 1),
              _guestRow('Children', 'Age 2–11', _children,
                  onChanged: (v) => setState(() => _children = v)),
              const Divider(height: 1),
              _guestRow('Infants', 'Under 2', _infants,
                  onChanged: (v) => setState(() => _infants = v)),
            ]),
          ),
          const SizedBox(height: 16),
          _line('${d.nights} nights accommodation', _money(_accommodation)),
          _line('Island Transfers', _money(_transfers)),
          _line('Service fee', 'Included'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total ($_guests guest${_guests == 1 ? '' : 's'})',
                  style: const TextStyle(
                      color: kBlue, fontWeight: FontWeight.w700, fontSize: 15)),
              Text(_money(_total),
                  style: const TextStyle(
                      color: kBlue, fontWeight: FontWeight.w700, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kBlue.withOpacity(.55),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: canBook
                  ? () {

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Booking ${widget.package.title} — ${_money(_total)}')));
              }
                  : null,
              child: Text('Book Now — ${_money(_total)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          if (_date == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(
                child: Text('Select a travel date to continue to payment.',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tierTile(int i) {
    final t = d.tiers[i];
    final sel = _tier == i;
    return GestureDetector(
      onTap: () => setState(() => _tier = i),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFD3DCEA) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? kBlue.withOpacity(.6) : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(t.name,
                  style: const TextStyle(
                      color: kBlue, fontWeight: FontWeight.w700, fontSize: 16)),
              if (t.popular) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFC9D3E6),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('Most Popular',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: kBlue)),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_money(t.price),
                  style: const TextStyle(
                      color: kBlue, fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text('/ person',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(t.desc,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _guestRow(String label, String sub, int value,
      {int min = 0, required ValueChanged<int> onChanged}) {
    Widget btn(IconData ic, VoidCallback f) => InkWell(
      onTap: f,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(6)),
        child: Icon(ic, size: 16),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(sub,
                  style: const TextStyle(fontSize: 11, color: Colors.black45)),
            ],
          ),
        ),
        btn(Icons.remove, () => onChanged((value - 1).clamp(min, 9))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('$value',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        btn(Icons.add, () => onChanged((value + 1).clamp(min, 9))),
      ]),
    );
  }

  Widget _line(String l, String r) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(l), Text(r)],
    ),
  );

  Widget _gallery() {
    final g = d.gallery;
    Widget pic(String path) => ClipRRect(
        borderRadius: BorderRadius.circular(12), child: _img(path));
    return _section(
      'Gallery',
      trailing: TextButton(
        style: TextButton.styleFrom(minimumSize: const Size(0, 36)),
        onPressed: () {},
        child: const Text('View All →'),
      ),
      child: SizedBox(
        height: 230,
        child: g.length < 3
            ? pic(g.first)
            : Row(children: [
          Expanded(child: pic(g[0])),
          const SizedBox(width: 8),
          Expanded(
            child: Column(children: [
              Expanded(child: SizedBox(width: double.infinity, child: pic(g[1]))),
              const SizedBox(height: 8),
              Expanded(child: SizedBox(width: double.infinity, child: pic(g[2]))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _review() => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: const Color(0xFFFFF6EA),
        borderRadius: BorderRadius.circular(16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          for (var i = 0; i < 5; i++)
            const Icon(Icons.star, size: 18, color: Color(0xFFF5A623)),
        ]),
        const SizedBox(height: 8),
        Text(d.reviewText),
        const SizedBox(height: 12),
        Row(children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.white,
            child: Text(d.reviewer.isEmpty ? '' : d.reviewer[0],
                style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.reviewer,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(d.reviewMeta,
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ]),
      ],
    ),
  );


  Widget _section(String title, {required Widget child, Widget? trailing}) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: kBlue)),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );

  Widget _img(String? asset) {
    Widget fallback() => Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF3B6BA5), Color(0xFF9CC3E6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
    );
    if (asset == null) return fallback();
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => fallback(),
    );
  }
}
