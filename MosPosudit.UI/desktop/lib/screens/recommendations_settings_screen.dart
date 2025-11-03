import 'package:flutter/material.dart';
import 'package:mosposudit_shared/services/settings_service.dart';
import 'package:mosposudit_shared/models/recommendation_settings.dart';
import '../core/snackbar_helper.dart';

class RecommendationsSettingsPage extends StatefulWidget {
  const RecommendationsSettingsPage({super.key});

  @override
  State<RecommendationsSettingsPage> createState() => _RecommendationsSettingsPageState();
}

class _RecommendationsSettingsPageState extends State<RecommendationsSettingsPage> {
  final SettingsService _settingsService = SettingsService();
  final TextEditingController _trainingIntervalController = TextEditingController(text: '7');
  
  RecommendationEngine _selectedEngine = RecommendationEngine.ruleBased;
  int _trainingIntervalDays = 7;
  DateTime? _lastTrainingDate;

  double _homePopularWeight = 40.0;
  double _homeContentBasedWeight = 30.0;
  double _homeTopRatedWeight = 30.0;

  double _cartFrequentlyBoughtWeight = 60.0;
  double _cartSimilarToolsWeight = 40.0;

  bool _isLoading = false;
  bool _hasChanges = false;
  bool _isTraining = false;
  RecommendationSettingsModel? _currentSettings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await _settingsService.getRecommendationSettings();
      
      setState(() {
        _selectedEngine = settings.engine;
        _trainingIntervalDays = settings.trainingIntervalDays;
        _trainingIntervalController.text = settings.trainingIntervalDays.toString();
        _lastTrainingDate = settings.lastTrainingDate;
        _homePopularWeight = settings.homePopularWeight;
        _homeContentBasedWeight = settings.homeContentBasedWeight;
        _homeTopRatedWeight = settings.homeTopRatedWeight;
        _cartFrequentlyBoughtWeight = settings.cartFrequentlyBoughtWeight;
        _cartSimilarToolsWeight = settings.cartSimilarToolsWeight;
        _currentSettings = settings;
        _isLoading = false;
        _hasChanges = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarHelper.showError(context, 'Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    final homeTotal = _homePopularWeight + _homeContentBasedWeight + _homeTopRatedWeight;
    if ((homeTotal - 100.0).abs() > 0.1) {
      SnackbarHelper.showError(context, 'Home recommendation weights must sum to 100%');
      return;
    }

    final cartTotal = _cartFrequentlyBoughtWeight + _cartSimilarToolsWeight;
    if ((cartTotal - 100.0).abs() > 0.1) {
      SnackbarHelper.showError(context, 'Cart recommendation weights must sum to 100%');
      return;
    }

    if (_selectedEngine != RecommendationEngine.ruleBased && _trainingIntervalDays <= 0) {
      _trainingIntervalDays = 7;
      _trainingIntervalController.text = '7';
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedSettings = await _settingsService.updateRecommendationSettings(
        engine: _selectedEngine,
        trainingIntervalDays: _trainingIntervalDays <= 0 ? 7 : _trainingIntervalDays,
        homePopularWeight: _homePopularWeight,
        homeContentBasedWeight: _homeContentBasedWeight,
        homeTopRatedWeight: _homeTopRatedWeight,
        cartFrequentlyBoughtWeight: _cartFrequentlyBoughtWeight,
        cartSimilarToolsWeight: _cartSimilarToolsWeight,
      );

      setState(() {
        _currentSettings = updatedSettings;
        _isLoading = false;
        _hasChanges = false;
      });

      SnackbarHelper.showSuccess(context, 'Recommendation settings saved successfully');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarHelper.showError(context, 'Error saving settings: ${e.toString()}');
    }
  }

  Future<void> _triggerTraining() async {
    setState(() {
      _isTraining = true;
    });

    try {
      final result = await _settingsService.triggerMLTraining();
      
      setState(() {
        _isTraining = false;
      });

      SnackbarHelper.showSuccess(
        context, 
        result['message'] ?? 'ML training triggered successfully!'
      );
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('Training Started'),
            ],
          ),
          content: Text(
            result['note'] ?? 'Training will start within 1-5 minutes and take 2-5 minutes to complete. Check worker logs for progress.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isTraining = false;
      });
      SnackbarHelper.showError(context, 'Error triggering training: ${e.toString()}');
    }
  }

  void _updateHomeWeight(String type, double value) {
    setState(() {
      _hasChanges = true;
      switch (type) {
        case 'popular':
          _homePopularWeight = value;
          break;
        case 'content':
          _homeContentBasedWeight = value;
          break;
        case 'toprated':
          _homeTopRatedWeight = value;
          break;
      }
      _normalizeHomeWeights();
    });
  }

  void _normalizeHomeWeights() {
    final total = _homePopularWeight + _homeContentBasedWeight + _homeTopRatedWeight;
    if ((total - 100.0).abs() > 0.1) {
      final diff = 100.0 - total;
      final sum = _homePopularWeight + _homeContentBasedWeight + _homeTopRatedWeight;
      if (sum > 0) {
        _homePopularWeight += diff * (_homePopularWeight / sum);
        _homeContentBasedWeight += diff * (_homeContentBasedWeight / sum);
        _homeTopRatedWeight += diff * (_homeTopRatedWeight / sum);
      }
    }
  }

  void _updateCartWeight(String type, double value) {
    setState(() {
      _hasChanges = true;
      switch (type) {
        case 'frequently':
          _cartFrequentlyBoughtWeight = value;
          break;
        case 'similar':
          _cartSimilarToolsWeight = value;
          break;
      }
      _normalizeCartWeights();
    });
  }

  void _normalizeCartWeights() {
    final total = _cartFrequentlyBoughtWeight + _cartSimilarToolsWeight;
    if ((total - 100.0).abs() > 0.1) {
      final diff = 100.0 - total;
      _cartSimilarToolsWeight += diff;
    }
  }

  double _getHomeTotal() {
    return _homePopularWeight + _homeContentBasedWeight + _homeTopRatedWeight;
  }

  double _getCartTotal() {
    return _cartFrequentlyBoughtWeight + _cartSimilarToolsWeight;
  }

  Widget _engineInfo(String title, String description, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _trainingIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recommendations Settings',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    if (_hasChanges)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Unsaved changes',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_hasChanges) const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _hasChanges ? _saveSettings : null,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadSettings,
                      tooltip: 'Reload Settings',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.psychology_outlined,
                                      size: 28,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Recommendation Engine',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Choose between rule-based, machine learning, or hybrid recommendations',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              DropdownButtonFormField<RecommendationEngine>(
                                value: _selectedEngine,
                                decoration: InputDecoration(
                                  labelText: 'Engine Type',
                                  prefixIcon: const Icon(Icons.settings_suggest),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: RecommendationEngine.values.map((engine) {
                                  return DropdownMenuItem(
                                    value: engine,
                                    child: Text(engine.displayName),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedEngine = value;
                                      _hasChanges = true;
                                      
                                      if (value != RecommendationEngine.ruleBased) {
                                        if (_trainingIntervalDays <= 0) {
                                          _trainingIntervalDays = 7;
                                          _trainingIntervalController.text = '7';
                                        }
                                      }
                                    });
                                  }
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              if (_selectedEngine != RecommendationEngine.ruleBased)
                                Column(
                                  children: [
                                    TextFormField(
                                      controller: _trainingIntervalController,
                                      decoration: InputDecoration(
                                        labelText: 'Training Interval (days)',
                                        prefixIcon: const Icon(Icons.schedule),
                                        suffix: const Text('days'),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        helperText: 'ML model will retrain every N days (default: 7)',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        final days = int.tryParse(value);
                                        if (days != null && days >= 1 && days <= 365) {
                                          setState(() {
                                            _trainingIntervalDays = days;
                                            _hasChanges = true;
                                          });
                                        } else if (value.isEmpty) {
                                          setState(() {
                                            _trainingIntervalDays = 7;
                                            _hasChanges = true;
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    Row(
                                      children: [
                                        if (_lastTrainingDate != null)
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.green.shade200),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.check_circle_outline, 
                                                      color: Colors.green.shade700, size: 20),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Last trained: ${_lastTrainingDate!.toString().substring(0, 16)}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.green.shade700,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        if (_lastTrainingDate != null) const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: _isTraining ? null : _triggerTraining,
                                          icon: _isTraining 
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : const Icon(Icons.play_arrow),
                                          label: Text(_isTraining ? 'Starting...' : 'Train Now'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.purple,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              
                              const SizedBox(height: 16),
                              
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _engineInfo('Rule-Based', 
                                        'Uses predefined rules and weights. Fast, predictable, no training needed.',
                                        Icons.rule),
                                    const Divider(height: 24),
                                    _engineInfo('Machine Learning', 
                                        'Uses Matrix Factorization to learn user preferences. Requires training data.',
                                        Icons.psychology),
                                    const Divider(height: 24),
                                    _engineInfo('Hybrid', 
                                        'Tries ML first, falls back to rules if needed. Best of both worlds!',
                                        Icons.sync_alt),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.home_outlined,
                                      size: 28,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Home Recommendations',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Configure weights for home screen recommendations (must sum to 100%)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              _WeightSlider(
                                label: 'Popular / Trending',
                                description: 'Tools that are frequently rented',
                                value: _homePopularWeight,
                                onChanged: (value) => _updateHomeWeight('popular', value),
                                color: Colors.blue,
                                icon: Icons.trending_up_outlined,
                              ),
                              const SizedBox(height: 24),

                              _WeightSlider(
                                label: 'Content-Based',
                                description: 'Based on user\'s favorite categories',
                                value: _homeContentBasedWeight,
                                onChanged: (value) => _updateHomeWeight('content', value),
                                color: Colors.green,
                                icon: Icons.category_outlined,
                              ),
                              const SizedBox(height: 24),

                              _WeightSlider(
                                label: 'Top Rated',
                                description: 'Highest rated tools',
                                value: _homeTopRatedWeight,
                                onChanged: (value) => _updateHomeWeight('toprated', value),
                                color: Colors.amber,
                                icon: Icons.star_outlined,
                              ),
                              
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: (_getHomeTotal() - 100.0).abs() < 0.1
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: (_getHomeTotal() - 100.0).abs() < 0.1
                                            ? Colors.green.shade200
                                            : Colors.red.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      '${_getHomeTotal().toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: (_getHomeTotal() - 100.0).abs() < 0.1
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 28,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Cart Recommendations',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Configure weights for cart recommendations (must sum to 100%)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              _WeightSlider(
                                label: 'Frequently Bought Together',
                                description: 'Tools often purchased with the selected tool',
                                value: _cartFrequentlyBoughtWeight,
                                onChanged: (value) => _updateCartWeight('frequently', value),
                                color: Colors.purple,
                                icon: Icons.shopping_bag_outlined,
                              ),
                              const SizedBox(height: 24),

                              _WeightSlider(
                                label: 'Similar Tools',
                                description: 'Tools from the same category with similar ratings',
                                value: _cartSimilarToolsWeight,
                                onChanged: (value) => _updateCartWeight('similar', value),
                                color: Colors.teal,
                                icon: Icons.compare_arrows_outlined,
                              ),
                              
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: (_getCartTotal() - 100.0).abs() < 0.1
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: (_getCartTotal() - 100.0).abs() < 0.1
                                            ? Colors.green.shade200
                                            : Colors.red.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      '${_getCartTotal().toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: (_getCartTotal() - 100.0).abs() < 0.1
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Card(
                        elevation: 1,
                        color: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blue.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'These weights determine how recommendations are calculated. '
                                  'All weights must sum to exactly 100%. Settings are saved locally '
                                  'and will be applied when the recommendation system is updated.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
}

class _WeightSlider extends StatelessWidget {
  final String label;
  final String description;
  final double value;
  final ValueChanged<double> onChanged;
  final MaterialColor color;
  final IconData icon;

  const _WeightSlider({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.shade200),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 1000,
          label: '${value.toStringAsFixed(1)}%',
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

