  import 'package:flutter/material.dart';
  import 'package:flutter_final_66111741/database/database_helper.dart';
  import 'package:flutter_final_66111741/screens/Report_Incident.dart';
  import 'package:flutter_final_66111741/screens/Incident_List.dart';
  import 'package:flutter_final_66111741/screens/Edit_Polling_Station.dart';
  import 'package:flutter_final_66111741/screens/Search_&_Filter.dart';

  class HomeScreen extends StatefulWidget {
    const HomeScreen({super.key});

    @override
    State<HomeScreen> createState() => _HomeScreenState();
  }

  class _HomeScreenState extends State<HomeScreen> {
    int _selectedIndex = 0;
    int _totalIncidents = 0;
    List<Map<String, dynamic>> _top3Stations = [];
    bool _isLoading = true;

    @override
    void initState() {
      super.initState();
      _loadDashboardData();
    }

    Future<void> _loadDashboardData() async {
      try {
        final syncResult = await DatabaseHelper.instance.syncPendingReports();
        if (mounted && (syncResult['synced'] as int) > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync ข้อมูลขึ้น Firebase สำเร็จ ${syncResult['synced']} รายการ'),
              backgroundColor: Colors.green,
            ),
          );
        }

        final total = await DatabaseHelper.instance.getTotalIncidentReports();
        final top3 = await DatabaseHelper.instance.getTop3PollingStations();
        setState(() {
          _totalIncidents = total;
          _top3Stations = top3;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Election Incident Report'),
          centerTitle: true,
        ),
        body: _selectedIndex == 0
            ? _buildDashboard()
            : IndexedStack(
                index: _selectedIndex - 1,
                children: const [
                  ReportFormScreen(),
                  EditPollingStationScreen(),
                  ReportListScreen(),
                  SearchFilterScreen(),
                ],
              ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.notification_add_outlined),
              selectedIcon: Icon(Icons.notification_add),
              label: 'Report',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_outlined),
              selectedIcon: Icon(Icons.edit),
              label: 'Edit Station',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'List',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Search',
            ),
          ],
        ),
      );
    }

    Widget _buildDashboard() {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Home',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('การแจ้งเหตุทั้งหมดแบบ Offline',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Text('$_totalIncidents',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('3 อันดับหน่วยเลือกตั้งที่ถูกร้องเรียนมากที่สุด',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else if (_top3Stations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('ไม่มีข้อมูลการร้องเรียน'),
                      )
                    else
                      Column(
                        children: List.generate(_top3Stations.length, (index) {
                          final station = _top3Stations[index];
                          final rank = index + 1;
                          final complaintCount = station['complaint_count'] as int;
                          final stationName = station['station_name'] as String;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('อันดับที่ $rank',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(stationName,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text('$complaintCount เรื่อง',
                                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    }
  }
