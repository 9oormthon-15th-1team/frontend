import 'package:flutter/material.dart';
import '../../core/models/pothole.dart';
import '../../core/services/api/pothole_api_service.dart';
import '../../widgets/loading/loading_widget.dart';

class PotholeListPage extends StatefulWidget {
  const PotholeListPage({super.key});

  @override
  State<PotholeListPage> createState() => _PotholeListPageState();
}

class _PotholeListPageState extends State<PotholeListPage> {
  List<Pothole> potholes = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadPotholes();
  }

  Future<void> _loadPotholes() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final fetchedPotholes = await PotholeApiService.getPotholes();

      setState(() {
        potholes = fetchedPotholes;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pothole List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPotholes,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: LoadingWidget());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading potholes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPotholes,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (potholes.isEmpty) {
      return const Center(
        child: Text('No potholes found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPotholes,
      child: ListView.builder(
        itemCount: potholes.length,
        itemBuilder: (context, index) {
          final pothole = potholes[index];
          return _buildPotholeCard(pothole);
        },
      ),
    );
  }

  Widget _buildPotholeCard(Pothole pothole) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor(pothole.severity),
          child: Icon(
            Icons.warning,
            color: Colors.white,
          ),
        ),
        title: Text('Pothole #${pothole.id}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${pothole.latitude.toStringAsFixed(6)}, ${pothole.longitude.toStringAsFixed(6)}'),
            Text('Status: ${pothole.status}'),
            Text('Severity: ${pothole.severity}'),
            if (pothole.description != null)
              Text('Description: ${pothole.description}'),
            Text('Created: ${_formatDate(pothole.createdAt)}'),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          // TODO: Navigate to detail page
        },
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        return Colors.red;
      case 'medium':
      case 'moderate':
        return Colors.orange;
      case 'low':
      case 'minor':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}