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
      title: 'कलेक्टर गाइडलाइन दर',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const SearchScreen(),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<String> districts = [];
  List<String> tehsils = [];
  List<String> villages = [];
  List<String> wards = [];

  String? selectedDistrict;
  String? selectedTehsil;
  String? selectedVillage;
  String? selectedWard;

  String? resultRate;
  String? resultDetails;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadDistricts();
  }

  Future<void> loadDistricts() async {
    try {
      final data = await supabase.from('guidelines').select('district');
      final unique = data.map((e) => e['district'].toString()).toSet().toList();
      setState(() {
        districts = unique;
      });
    } catch (e) {
      debugPrint('Error loading districts: $e');
    }
  }

  Future<void> loadTehsils(String district) async {
    final data = await supabase.from('guidelines').select('tehsil').eq('district', district);
    final unique = data.map((e) => e['tehsil'].toString()).toSet().toList();
    setState(() {
      tehsils = unique;
      selectedTehsil = null;
      villages = [];
      selectedVillage = null;
      wards = [];
      selectedWard = null;
      resultRate = null;
    });
  }

  Future<void> loadVillages(String tehsil) async {
    final data = await supabase
        .from('guidelines')
        .select('village')
        .eq('district', selectedDistrict!)
        .eq('tehsil', tehsil);
    final unique = data.map((e) => e['village'].toString()).toSet().toList();
    setState(() {
      villages = unique;
      selectedVillage = null;
      wards = [];
      selectedWard = null;
      resultRate = null;
    });
  }

  Future<void> loadWards(String village) async {
    final data = await supabase
        .from('guidelines')
        .select('ward')
        .eq('district', selectedDistrict!)
        .eq('tehsil', selectedTehsil!)
        .eq('village', village);
    final unique = data.map((e) => e['ward'].toString()).toSet().toList();
    setState(() {
      wards = unique;
      selectedWard = null;
      resultRate = null;
    });
  }

  Future<void> fetchRate(String ward) async {
    setState(() => isLoading = true);
    final data = await supabase
        .from('guidelines')
        .select('rate, details')
        .eq('district', selectedDistrict!)
        .eq('tehsil', selectedTehsil!)
        .eq('village', selectedVillage!)
        .eq('ward', ward)
        .limit(1);

    if (data.isNotEmpty) {
      setState(() {
        resultRate = data[0]['rate']?.toString();
        resultDetails = data[0]['details']?.toString();
      });
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏛️ गाइडलाइन दरें', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildDropdown('1. ज़िला चुनें', districts, selectedDistrict, (val) {
              setState(() => selectedDistrict = val);
              if (val != null) loadTehsils(val);
            }),
            const SizedBox(height: 12),
            buildDropdown('2. तहसील चुनें', tehsils, selectedTehsil, (val) {
              setState(() => selectedTehsil = val);
              if (val != null) loadVillages(val);
            }),
            const SizedBox(height: 12),
            buildDropdown('3. गाँव / शहर चुनें', villages, selectedVillage, (val) {
              setState(() => selectedVillage = val);
              if (val != null) loadWards(val);
            }),
            const SizedBox(height: 12),
            buildDropdown('4. वार्ड / मोहल्ला चुनें', wards, selectedWard, (val) {
              setState(() => selectedWard = val);
              if (val != null) fetchRate(val);
            }),
            const SizedBox(height: 24),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (resultRate != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'कलेक्टर गाइडलाइन दर',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹ $resultRate',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        resultDetails?.isNotEmpty == true ? resultDetails! : 'सामान्य दर सूची',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildDropdown(
    String hint,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint),
          value: selectedValue,
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: items.isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}

