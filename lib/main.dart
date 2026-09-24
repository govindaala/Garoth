import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dcbtdftgjyokioqcpumv.supabase.co',
    anonKey: 'sb_publishable_u6nxcL145Z-HsaKiOlfjoQ_DCvKJrGO',
  );
  runApp(const GuidelineApp());
}

final supabase = Supabase.instance.client;

class GuidelineApp extends StatelessWidget {
  const GuidelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collector Guideline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E3A8A),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const GuidelineScreen(),
    );
  }
}

class GuidelineScreen extends StatefulWidget {
  const GuidelineScreen({super.key});

  @override
  State<GuidelineScreen> createState() => _GuidelineScreenState();
}

class _GuidelineScreenState extends State<GuidelineScreen> {
  List<String> districts = [];
  List<String> tehsils = [];
  List<String> subAreas = [];
  List<String> wards = [];
  List<String> locations = [];

  String? selectedDistrict;
  String? selectedTehsil;
  String? selectedSubArea;
  String? selectedWard;
  String? selectedLocation;

  Map<String, dynamic>? currentData;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadDistricts();
  }

  // 1. Zila load karein
  Future<void> loadDistricts() async {
    try {
      final res = await supabase.rpc('get_districts');
      final list = (res as List).map((e) => e['district'].toString().trim()).toList();
      setState(() => districts = list);
    } catch (e) {
      debugPrint('District load error: $e');
    }
  }

  // 2. Tehsil load karein
  Future<void> loadTehsils(String district) async {
    try {
      final res = await supabase.rpc('get_tehsils', params: {'d': district});
      final list = (res as List).map((e) => e['tehsil'].toString().trim()).toList();
      setState(() {
        tehsils = list;
        selectedTehsil = null;
        subAreas = [];
        selectedSubArea = null;
        wards = [];
        selectedWard = null;
        locations = [];
        selectedLocation = null;
        currentData = null;
      });
    } catch (e) {
      debugPrint('Tehsil load error: $e');
    }
  }

  // 3. Sub-Area (Nikay / Gramin) load karein
  Future<void> loadSubAreas(String tehsil) async {
    try {
      final res = await supabase.rpc('get_subareas', params: {
        'd': selectedDistrict!,
        't': tehsil,
      });
      final list = (res as List).map((e) => e['sub_area'].toString().trim()).toList();
      setState(() {
        subAreas = list;
        selectedSubArea = null;
        wards = [];
        selectedWard = null;
        locations = [];
        selectedLocation = null;
        currentData = null;
      });
    } catch (e) {
      debugPrint('SubArea load error: $e');
    }
  }

  // 4. Ward / Halka load karein
  Future<void> loadWards(String subArea) async {
    try {
      final res = await supabase.rpc('get_wards', params: {
        'd': selectedDistrict!,
        't': selectedTehsil!,
        's': subArea,
      });
      final list = (res as List).map((e) => e['ward_halka'].toString().trim()).toList();
      setState(() {
        wards = list;
        selectedWard = null;
        locations = [];
        selectedLocation = null;
        currentData = null;
      });
    } catch (e) {
      debugPrint('Ward load error: $e');
    }
  }

  // 5. Colony / Sadak / Gaon load karein
  Future<void> loadLocations(String ward) async {
    try {
      final res = await supabase.rpc('get_locations', params: {
        'd': selectedDistrict!,
        't': selectedTehsil!,
        's': selectedSubArea!,
        'w': ward,
      });
      final list = (res as List).map((e) => e['location_name'].toString().trim()).toList();
      setState(() {
        locations = list;
        selectedLocation = null;
        currentData = null;
      });
    } catch (e) {
      debugPrint('Locations load error: $e');
    }
  }

  // 6. Record fetch karein
  Future<void> fetchRecord(String location) async {
    setState(() => isLoading = true);
    final data = await supabase
        .from('guidelines')
        .select()
        .eq('district', selectedDistrict!)
        .eq('tehsil', selectedTehsil!)
        .eq('sub_area', selectedSubArea!)
        .eq('ward_halka', selectedWard!)
        .eq('location_name', location)
        .limit(1);

    if (data.isNotEmpty) {
      setState(() => currentData = data[0]);
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏛️ कलेक्टर गाइडलाइन मूल्यांकन', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('स्थान का चयन करें (Location Filter)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    const SizedBox(height: 12),
                    buildDropdown('1. ज़िला चुनें (Select District)', districts, selectedDistrict, (val) {
                      setState(() => selectedDistrict = val);
                      if (val != null) loadTehsils(val);
                    }),
                    const SizedBox(height: 10),
                    buildDropdown('2. तहसील चुनें (Select Tehsil)', tehsils, selectedTehsil, (val) {
                      setState(() => selectedTehsil = val);
                      if (val != null) loadSubAreas(val);
                    }),
                    const SizedBox(height: 10),
                    buildDropdown('3. निकाय / ग्रामीण क्षेत्र', subAreas, selectedSubArea, (val) {
                      setState(() => selectedSubArea = val);
                      if (val != null) loadWards(val);
                    }),
                    const SizedBox(height: 10),
                    buildDropdown('4. वार्ड / हल्का नंबर', wards, selectedWard, (val) {
                      setState(() => selectedWard = val);
                      if (val != null) loadLocations(val);
                    }),
                    const SizedBox(height: 10),
                    buildDropdown('5. मोहल्ला / कॉलोनी / सड़क / गाँव', locations, selectedLocation, (val) {
                      setState(() => selectedLocation = val);
                      if (val != null) fetchRecord(val);
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading) const CircularProgressIndicator(),
            if (currentData != null) buildDetailsView(currentData!),
          ],
        ),
      ),
    );
  }

  Widget buildDropdown(String hint, List<String> items, String? val, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          value: val,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: items.isEmpty ? null : onChanged,
        ),
      ),
    );
  }

  Widget buildDetailsView(Map<String, dynamic> d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d['location_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('${d['ward_halka']} | ${d['sub_area']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 2),
              Text('तहसील: ${d['tehsil']} | ज़िला: ${d['district'] ?? "मंदसौर"}', style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        buildSectionHeader('🏞️ भूखण्ड दरें (Plot Rates)'),
        Row(
          children: [
            Expanded(child: buildRateCard('आवासीय (Res)', d['plot_residential'], '₹/वर्ग मी.', Colors.blue.shade50, Colors.blue.shade900)),
            const SizedBox(width: 8),
            Expanded(child: buildRateCard('व्यावसायिक (Comm)', d['plot_commercial'], '₹/वर्ग मी.', Colors.amber.shade50, Colors.amber.shade900)),
            const SizedBox(width: 8),
            Expanded(child: buildRateCard('औद्योगिक (Ind)', d['plot_industrial'], '₹/वर्ग मी.', Colors.purple.shade50, Colors.purple.shade900)),
          ],
        ),
        const SizedBox(height: 12),

        if (d['agri_irrigated'] != '-' || d['agri_unirrigated'] != '-') ...[
          buildSectionHeader('🌾 कृषि भूमि दरें (Agriculture - प्रति हेक्टेयर)'),
          Row(
            children: [
              Expanded(child: buildRateCard('सिंचित (Irrigated)', d['agri_irrigated'], '₹/हेक्टेयर', Colors.green.shade50, Colors.green.shade900)),
              const SizedBox(width: 8),
              Expanded(child: buildRateCard('असिंचित (Unirrigated)', d['agri_unirrigated'], '₹/हेक्टेयर', Colors.orange.shade50, Colors.orange.shade900)),
            ],
          ),
          const SizedBox(height: 12),
        ],

        buildSectionHeader('🏢 भवन निर्माण दरें (Building Construction - ₹/वर्ग मी.)'),
        Row(
          children: [
            Expanded(child: buildRateCard('RCC मकान', d['rcc_rate'], '₹/वर्ग मी.', Colors.indigo.shade50, Colors.indigo.shade900)),
            const SizedBox(width: 8),
            Expanded(child: buildRateCard('दुकान (Shop)', d['shop_rate'], '₹/वर्ग मी.', Colors.teal.shade50, Colors.teal.shade900)),
            const SizedBox(width: 8),
            Expanded(child: buildRateCard('ऑफिस (Office)', d['office_rate'], '₹/वर्ग मी.', Colors.cyan.shade50, Colors.cyan.shade900)),
          ],
        ),
      ],
    );
  }

  Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 4.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
    );
  }

  Widget buildRateCard(String title, dynamic rate, String unit, Color bg, Color txt) {
    final rateStr = (rate == null || rate.toString().trim() == '-' || rate.toString().trim() == '0') ? '-' : '₹ ${rate.toString()}';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: txt.withOpacity(0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: txt)),
          const SizedBox(height: 4),
          Text(rateStr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: txt)),
          Text(unit, style: TextStyle(fontSize: 9, color: txt.withOpacity(0.7))),
        ],
      ),
    );
  }
}
