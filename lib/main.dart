import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. AdMob SDK को सुरक्षित तरीके से इनिशियलाइज करें
  try {
    MobileAds.instance.initialize();
  } catch (e) {
    debugPrint("AdMob init error: $e");
  }

  // 2. Supabase को सुरक्षित try-catch में रखें ताकि क्रैश न हो
  try {
    await Supabase.initialize(
      url: 'https://dcbtdftgjyokioqcpumv.supabase.co',
      anonKey: 'sb_publishable_u6nxcL145Z-HsaKiOlfjoQ_DCvKJrGO',
    );
  } catch (e) {
    debugPrint("Supabase init error: $e");
  }

  runApp(const GuidelineApp());
}

class GuidelineApp extends StatelessWidget {
  const GuidelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MP Collector Guideline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  String? selectedDistrict;
  String? selectedTehsil;
  String? selectedSubArea;
  String? selectedWard;
  String? selectedLocation;

  List<String> districts = [];
  List<String> tehsils = [];
  List<String> subAreas = [];
  List<String> wards = [];
  List<String> locations = [];

  Map<String, dynamic>? guidelineData;
  bool isLoading = true; // ऐप शुरू होते ही लोडिंग ऑन रहेगी

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final String _adUnitId = 'ca-app-pub-1190693135801072/8507449433';

  @override
  void initState() {
    super.initState();
    loadDistricts();
    _loadBannerAd();
    smartTrackAppOpen();
  }

  // Smart & Lightweight Tracking Function
  void smartTrackAppOpen() {
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        
        String? deviceId = prefs.getString('device_id');
        if (deviceId == null) {
          deviceId = const Uuid().v4();
          await prefs.setString('device_id', deviceId);
          await supabase.from('devices').upsert({'device_id': deviceId});
        }

        final today = DateTime.now().toIso8601String().split('T')[0];
        final lastTrackedDate = prefs.getString('last_tracked_date');

        if (lastTrackedDate != today) {
          await prefs.setString('last_tracked_date', today);
          await supabase.from('app_opens').insert({'device_id': deviceId});
        }
      } catch (e) {
        debugPrint('Tracking silent error: $e');
      }
    });
  }

  void _loadBannerAd() {
    try {
      BannerAd(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) return;
            setState(() {
              _bannerAd = ad as BannerAd;
              _isAdLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, err) {
            ad.dispose();
          },
        ),
      ).load();
    } catch (e) {
      debugPrint("Ad load error: $e");
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> loadDistricts() async {
    try {
      final res = await supabase.rpc('get_districts');
      final list = (res as List)
          .map((e) => e['district'].toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      if (!mounted) return;
      setState(() {
        districts = list;
        isLoading = false;
        if (districts.isNotEmpty) {
          selectedDistrict = districts.contains('मंदसौर') ? 'मंदसौर' : districts.first;
          loadTehsils(selectedDistrict!);
        }
      });
    } catch (e) {
      debugPrint('Districts load error: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> loadTehsils(String district) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      selectedTehsil = null;
      selectedSubArea = null;
      selectedWard = null;
      selectedLocation = null;
      guidelineData = null;
      tehsils = [];
      subAreas = [];
      wards = [];
      locations = [];
    });
    try {
      final res = await supabase.rpc('get_tehsils', params: {'p_district': district});
      final list = (res as List)
          .map((e) => e['tehsil'].toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      if (!mounted) return;
      setState(() => tehsils = list);
    } catch (e) {
      debugPrint('Tehsil error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loadSubAreas(String tehsil) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      selectedSubArea = null;
      selectedWard = null;
      selectedLocation = null;
      guidelineData = null;
      subAreas = [];
      wards = [];
      locations = [];
    });
    try {
      final res = await supabase.rpc('get_sub_areas', params: {
        'p_district': selectedDistrict!,
        'p_tehsil': tehsil,
      });
      final list = (res as List)
          .map((e) => e['sub_area'].toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      if (!mounted) return;
      setState(() => subAreas = list);
    } catch (e) {
      debugPrint('SubArea error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loadWards(String subArea) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      selectedWard = null;
      selectedLocation = null;
      guidelineData = null;
      wards = [];
      locations = [];
    });
    try {
      final res = await supabase.rpc('get_wards', params: {
        'p_district': selectedDistrict!,
        'p_tehsil': selectedTehsil!,
        'p_sub_area': subArea,
      });
      final list = (res as List)
          .map((e) => e['ward_halka'].toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      if (!mounted) return;
      setState(() => wards = list);
    } catch (e) {
      debugPrint('Ward error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loadLocations(String ward) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      selectedLocation = null;
      guidelineData = null;
      locations = [];
    });
    try {
      final res = await supabase.rpc('get_locations', params: {
        'p_district': selectedDistrict!,
        'p_tehsil': selectedTehsil!,
        'p_sub_area': selectedSubArea!,
        'p_ward': ward,
      });
      final list = (res as List)
          .map((e) => e['location_name'].toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      if (!mounted) return;
      setState(() => locations = list);
    } catch (e) {
      debugPrint('Location error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loadRateDetails(String loc) async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final res = await supabase
          .from('guidelines')
          .select()
          .eq('district', selectedDistrict!)
          .eq('tehsil', selectedTehsil!)
          .eq('sub_area', selectedSubArea!)
          .eq('ward_halka', selectedWard!)
          .eq('location_name', loc)
          .limit(1)
          .maybeSingle();
      
      if (!mounted) return;
      setState(() => guidelineData = res);
    } catch (e) {
      debugPrint('Rate error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _openSheet(String title, List<String> items, Function(String) onPick) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final list = items.where((i) => i.toLowerCase().contains(filter.toLowerCase())).toList();
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'यहाँ खोजें...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    onChanged: (v) => setSheetState(() => filter = v),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: list.isEmpty
                        ? const Center(child: Text('कोई रिकॉर्ड नहीं मिला'))
                        : ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, idx) => ListTile(
                              dense: true,
                              title: Text(list[idx], style: const TextStyle(fontSize: 14)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                              onTap: () {
                                Navigator.pop(context);
                                onPick(list[idx]);
                              },
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('कलेक्टर गाइडलाइन 2026-27', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📍 स्थान चुनें', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 12),
                  _tile('1', 'ज़िला', selectedDistrict, () => _openSheet('ज़िला चुनें', districts, (v) { selectedDistrict = v; loadTehsils(v); })),
                  _tile('2', 'तहसील', selectedTehsil, () => _openSheet('तहसील चुनें', tehsils, (v) { selectedTehsil = v; loadSubAreas(v); }), isEnabled: selectedDistrict != null && tehsils.isNotEmpty),
                  _tile('3', 'निकाय / उप-क्षेत्र', selectedSubArea, () => _openSheet('निकाय चुनें', subAreas, (v) { selectedSubArea = v; loadWards(v); }), isEnabled: selectedTehsil != null && subAreas.isNotEmpty),
                  _tile('4', 'वार्ड / हल्का', selectedWard, () => _openSheet('वार्ड/हल्का चुनें', wards, (v) { selectedWard = v; loadLocations(v); }), isEnabled: selectedSubArea != null && wards.isNotEmpty),
                  _tile('5', 'कॉलोनी / गाँव', selectedLocation, () => _openSheet('कॉलोनी/गाँव चुनें', locations, (v) { selectedLocation = v; loadRateDetails(v); }), isEnabled: selectedWard != null && locations.isNotEmpty),
                ],
              ),
            ),
            if (isLoading) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
            if (guidelineData != null) _buildRates(guidelineData!),
          ],
        ),
      ),
      bottomNavigationBar: _isAdLoaded && _bannerAd != null
          ? Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
    );
  }

  Widget _tile(String step, String label, String? val, VoidCallback onTap, {bool isEnabled = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: isEnabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(radius: 12, backgroundColor: isEnabled ? const Color(0xFF1E3A8A) : Colors.grey[400], child: Text(step, style: const TextStyle(fontSize: 11, color: Colors.white))),
        title: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        subtitle: Text(val ?? 'चुनें...', style: TextStyle(fontSize: 14, fontWeight: val != null ? FontWeight.bold : FontWeight.normal, color: val != null ? const Color(0xFF0F172A) : Colors.grey)),
        trailing: Icon(Icons.arrow_drop_down, color: isEnabled ? const Color(0xFF1E3A8A) : Colors.grey),
        onTap: isEnabled ? onTap : null,
      ),
    );
  }

  Widget _buildRates(Map<String, dynamic> d) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d['location_name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          const Divider(height: 20),

          _box('1. भूखण्ड दरें (Plot Rates ₹/वर्ग मी.)', [
            _row('आवासीय भूखण्ड', d['plot_residential']),
            _row('व्यावसायिक भूखण्ड', d['plot_commercial']),
            _row('औद्योगिक भूखण्ड', d['plot_industrial']),
          ]),

          _box('2. आवासीय निर्माण (₹/वर्ग मी.)', [
            _row('RCC निर्माण', d['rcc_residential']),
            _row('पक्का निर्माण', d['pucca_residential']),
            _row('अर्ध-पक्का निर्माण', d['semi_pucca_residential']),
            _row('कच्चा / टीन शेड', d['kachha_residential']),
          ]),

          _box('3. दुकान / व्यावसायिक (₹/वर्ग मी.)', [
            _row('दुकान (RCC)', d['shop_rcc']),
            _row('दुकान (पक्का)', d['shop_pucca']),
            _row('दुकान (अर्ध-pक्का)', d['shop_semi_pucca']),
          ]),

          _box('4. बहुमंजिला परिसर (₹/वर्ग मी.)', [
            _row('मल्टी आवासीय', d['multi_residential']),
            _row('मल्टी व्यावसायिक', d['multi_commercial']),
          ]),

          _box('5. कृषि भूमि (₹/हेक्टेयर)', [
            _row('🌾 सिंचित भूमि', '₹ ${d['agri_irrigated']}', color: Colors.green[700], isBold: true),
            _row('🍂 असिंचित भूमि', '₹ ${d['agri_unirrigated']}', color: Colors.orange[800], isBold: true),
          ]),

          if ((d['extra_rate_1'] != null && d['extra_rate_1'] != '-') || (d['extra_rate_2'] != null && d['extra_rate_2'] != '-'))
            _box('6. विशेष / मार्ग दरें', [
              _row('मार्ग दर 1', d['extra_rate_1']),
              _row('मार्ग दर 2', d['extra_rate_2']),
            ]),
        ],
      ),
    );
  }

  Widget _box(String t, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        const SizedBox(height: 6),
        ...items,
      ]),
    );
  }

  Widget _row(String l, dynamic v, {bool isBold = false, Color? color}) {
    final str = (v == null || v == '' || v == 'None') ? '-' : v.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569))),
          Text(str.startsWith('₹') ? str : '₹ $str', style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
