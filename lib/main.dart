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

class GuidelineApp extends StatelessWidget {
  const GuidelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MP Collector Guideline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F4C81)),
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

  Map<String, dynamic>? guidelineDetails;
  bool isLoading = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadDistricts();
  }

  Future<void> loadDistricts() async {
    setState(() => isLoading = true);
    try {
      final res = await supabase.from('guidelines').select('district');
      final uniqueDistricts = (res as List)
          .map((e) => e['district'].toString().trim())
          .toSet()
          .toList()..sort();
      setState(() {
        districts = uniqueDistricts;
        if (districts.isNotEmpty) {
          selectedDistrict = districts.contains('मंदसौर') ? 'मंदसौर' : districts.first;
          loadTehsils(selectedDistrict!);
        }
      });
    } catch (e) {
      debugPrint('Error loading districts: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadTehsils(String district) async {
    setState(() {
      isLoading = true;
      selectedTehsil = null;
      selectedSubArea = null;
      selectedWard = null;
      selectedLocation = null;
      guidelineDetails = null;
    });
    try {
      final res = await supabase
          .from('guidelines')
          .select('tehsil')
          .eq('district', district);
      final uniqueTehsils = (res as List)
          .map((e) => e['tehsil'].toString().trim())
          .toSet()
          .toList()..sort();
      setState(() => tehsils = uniqueTehsils);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadSubAreas(String tehsil) async {
    setState(() {
      isLoading = true;
      selectedSubArea = null;
      selectedWard = null;
      selectedLocation = null;
      guidelineDetails = null;
    });
    try {
      final res = await supabase
          .from('guidelines')
          .select('sub_area')
          .eq('district', selectedDistrict!)
          .eq('tehsil', tehsil);
      final unique = (res as List)
          .map((e) => e['sub_area'].toString().trim())
          .toSet()
          .toList()..sort();
      setState(() => subAreas = unique);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadWards(String subArea) async {
    setState(() {
      isLoading = true;
      selectedWard = null;
      selectedLocation = null;
      guidelineDetails = null;
    });
    try {
      final res = await supabase
          .from('guidelines')
          .select('ward_halka')
          .eq('district', selectedDistrict!)
          .eq('tehsil', selectedTehsil!)
          .eq('sub_area', subArea);
      final unique = (res as List)
          .map((e) => e['ward_halka'].toString().trim())
          .toSet()
          .toList()..sort();
      setState(() => wards = unique);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadLocations(String ward) async {
    setState(() {
      isLoading = true;
      selectedLocation = null;
      guidelineDetails = null;
    });
    try {
      final res = await supabase
          .from('guidelines')
          .select('location_name')
          .eq('district', selectedDistrict!)
          .eq('tehsil', selectedTehsil!)
          .eq('sub_area', selectedSubArea!)
          .eq('ward_halka', ward);
      final unique = (res as List)
          .map((e) => e['location_name'].toString().trim())
          .toSet()
          .toList()..sort();
      setState(() => locations = unique);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchGuidelineDetails(String location) async {
    setState(() => isLoading = true);
    try {
      final res = await supabase
          .from('guidelines')
          .select()
          .eq('district', selectedDistrict!)
          .eq('tehsil', selectedTehsil!)
          .eq('sub_area', selectedSubArea!)
          .eq('ward_halka', selectedWard!)
          .eq('location_name', location)
          .limit(1)
          .maybeSingle();
      setState(() => guidelineDetails = res);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'कलेक्टर गाइडलाइन मूल्यांकन 2026-27',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F4C81),
        elevation: 2,
      ),
      body: isLoading && districts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildDropdownCard(),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (guidelineDetails != null) _buildAll16RatesCard(guidelineDetails!),
                ],
              ),
            ),
    );
  }

  Widget _buildDropdownCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📍 स्थान चयन (Hierarchy Filter)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F4C81)),
            ),
            const SizedBox(height: 12),
            _buildDropdown('1. ज़िला (District)', districts, selectedDistrict, (v) {
              if (v != null) {
                selectedDistrict = v;
                loadTehsils(v);
              }
            }),
            _buildDropdown('2. तहसील (Tehsil)', tehsils, selectedTehsil, (v) {
              if (v != null) {
                selectedTehsil = v;
                loadSubAreas(v);
              }
            }),
            _buildDropdown('3. निकाय / क्षेत्र (Sub Area)', subAreas, selectedSubArea, (v) {
              if (v != null) {
                selectedSubArea = v;
                loadWards(v);
              }
            }),
            _buildDropdown('4. वार्ड / हल्का (Ward/Halka)', wards, selectedWard, (v) {
              if (v != null) {
                selectedWard = v;
                loadLocations(v);
              }
            }),
            _buildDropdown('5. कॉलोनी / सड़क / गाँव', locations, selectedLocation, (v) {
              if (v != null) {
                selectedLocation = v;
                fetchGuidelineDetails(v);
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? currentVal, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
        ),
        isExpanded: true,
        value: currentVal,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: items.isEmpty ? null : onChanged,
      ),
    );
  }

  Widget _buildAll16RatesCard(Map<String, dynamic> item) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(top: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF0F4C81), size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item['location_name'] ?? '',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F4C81)),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            _buildCategorySection('1. भूखण्ड दरें (Plot Rates ₹/वर्ग मी.)', [
              _rateTile('आवासीय भूखण्ड (Residential)', item['plot_residential']),
              _rateTile('व्यावसायिक भूखण्ड (Commercial)', item['plot_commercial']),
              _rateTile('औद्योगिक भूखण्ड (Industrial)', item['plot_industrial']),
            ]),

            _buildCategorySection('2. आवासीय भवन निर्माण (₹/वर्ग मी.)', [
              _rateTile('RCC भवन निर्माण', item['rcc_residential']),
              _rateTile('पक्का भवन निर्माण', item['pucca_residential']),
              _rateTile('अर्ध-पक्का निर्माण', item['semi_pucca_residential']),
              _rateTile('कच्चा / टीन शेड', item['kachha_residential']),
            ]),

            _buildCategorySection('3. व्यावसायिक निर्माण / दुकान (₹/वर्ग मी.)', [
              _rateTile('दुकान निर्माण (RCC)', item['shop_rcc']),
              _rateTile('दुकान निर्माण (पक्का)', item['shop_pucca']),
              _rateTile('दुकान निर्माण (अर्ध-पक्का)', item['shop_semi_pucca']),
            ]),

            _buildCategorySection('4. बहुमंजिला परिसर (Multi-Storey ₹/वर्ग मी.)', [
              _rateTile('मल्टी आवासीय फ्लैट', item['multi_residential']),
              _rateTile('मल्टी व्यावसायिक परिसर', item['multi_commercial']),
            ]),

            _buildCategorySection('5. कृषि भूमि दरें (₹/हेक्टेयर)', [
              _rateTile('🌾 सिंचित कृषि भूमि', '₹ ${item['agri_irrigated']}', isBold: true, color: Colors.green[800]),
              _rateTile('🍂 असिंचित कृषि भूमि', '₹ ${item['agri_unirrigated']}', isBold: true, color: Colors.orange[800]),
            ]),

            if ((item['extra_rate_1'] != null && item['extra_rate_1'] != '-') ||
                (item['extra_rate_2'] != null && item['extra_rate_2'] != '-'))
              _buildCategorySection('6. विशेष / मुख्य मार्ग दरें (₹/वर्ग मी.)', [
                _rateTile('सड़क/अतिरिक्त दर 1', item['extra_rate_1']),
                _rateTile('सड़क/अतिरिक्त दर 2', item['extra_rate_2']),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F4C81))),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _rateTile(String label, dynamic value, {bool isBold = false, Color? color}) {
    final displayVal = (value == null || value.toString().trim() == '' || value.toString().trim() == 'None')
        ? '-'
        : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
          Text(
            displayVal.startsWith('₹') ? displayVal : '₹ $displayVal',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
