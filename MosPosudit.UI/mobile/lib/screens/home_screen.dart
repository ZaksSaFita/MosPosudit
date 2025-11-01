import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mosposudit_shared/services/tool_service.dart';
import 'package:mosposudit_shared/services/category_service.dart';
import 'package:mosposudit_shared/services/recommendation_service.dart';
import 'package:mosposudit_shared/services/utility_service.dart';
import 'package:mosposudit_shared/models/tool.dart';
import 'package:mosposudit_shared/models/category.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int categoryId)? onCategoryTap;
  final void Function(int? toolId, int? categoryId)? onToolTap;
  final void Function()? onProfileTap;
  
  const HomeScreen({super.key, this.onCategoryTap, this.onToolTap, this.onProfileTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _toolService = ToolService();
  final _categoryService = CategoryService();
  final _recommendationService = RecommendationService();
  List<ToolModel> _tools = [];
  List<CategoryModel> _categories = [];
  List<ToolModel> _recommendedTools = [];
  bool _isLoading = true;
  bool _isLoadingRecommendations = true;
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isLoadingRecommendations = true;
    });

    try {
      final tools = await _toolService.fetchTools();
      final categories = await _categoryService.fetchCategories();
      
      // Load recommendations in parallel
      final recommendations = await _recommendationService.getHomeRecommendations(count: 6);

      if (mounted) {
        setState(() {
          _tools = tools;
          _categories = categories;
          _recommendedTools = recommendations;
          // If recommendations are empty, fallback to available tools
          if (_recommendedTools.isEmpty) {
            _recommendedTools = tools.where((t) => t.isAvailable == true && (t.quantity ?? 0) > 0).take(6).toList();
          }
          // Reset carousel index ako je veći od broja kategorija
          if (_currentCarouselIndex >= categories.length) {
            _currentCarouselIndex = 0;
          }
          _isLoading = false;
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingRecommendations = false;
          // Fallback to first 6 available tools if recommendations fail or are empty
          if (_recommendedTools.isEmpty) {
            _recommendedTools = _tools.where((t) => t.isAvailable == true && (t.quantity ?? 0) > 0).take(6).toList();
          }
        });
      }
    }
  }


  Widget _buildToolImage(ToolModel tool) {
    // Priority: base64 > asset filename (generated from name) > default icon
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _getImageWidget(tool),
      ),
    );
  }

  Widget _getImageWidget(ToolModel tool) {
    if (tool.imageBase64 != null && tool.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(tool.imageBase64!);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _defaultToolIcon();
          },
        );
      } catch (e) {
        return _defaultToolIcon();
      }
    } else if (tool.name != null && tool.name!.isNotEmpty) {
      final fileName = UtilityService.generateImageFileName(tool.name);
      if (fileName.isNotEmpty) {
        final assetPath = 'packages/mosposudit_shared/assets/images/tools/$fileName';
        print('HomeScreen: Attempting to load asset: $assetPath for tool: ${tool.name}');
        return Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print('HomeScreen: Error loading tool image: $assetPath for tool: ${tool.name}, error: $error');
            return _defaultToolIcon();
          },
        );
      }
    }
    return _defaultToolIcon();
  }

  Widget _defaultToolIcon() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.build,
        size: 60,
        color: Colors.blue.shade700,
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('MosPosudit'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: widget.onProfileTap,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Slideshow carousel for "Iznajmi alat" - using category images
            if (_categories.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 200,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 4),
                      autoPlayAnimationDuration: const Duration(milliseconds: 800),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enlargeCenterPage: false,
                      viewportFraction: 1.0,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentCarouselIndex = index;
                        });
                      },
                    ),
                    items: _categories.map((category) {
                      final fileName = UtilityService.generateImageFileName(category.name);
                      final imagePath = 'packages/mosposudit_shared/assets/images/categories/$fileName';
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () {
                                if (widget.onCategoryTap != null && category.id != 0) {
                                  widget.onCategoryTap!(category.id);
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Center(
                                            child: Text(
                                              category.name ?? 'Category',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  // Gradient overlay at the bottom
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.6),
                                            Colors.black.withOpacity(0.8),
                                          ],
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 20,
                                      ),
                                      child: Text(
                                        category.name ?? 'Category',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            // Carousel indicators
            if (_categories.isNotEmpty)
              SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_categories.length, (index) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentCarouselIndex == index
                            ? Colors.blue
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
            // Recommended for you section
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Recommended for you',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            if (_isLoadingRecommendations)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_recommendedTools.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tool = _recommendedTools[index];
                      
                      return Card(
                        elevation: 2,
                        color: tool.isAvailable == true ? null : Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            if (widget.onToolTap != null) {
                              widget.onToolTap!(tool.id, tool.categoryId);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Opacity(
                            opacity: tool.isAvailable == true ? 1.0 : 0.6,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        _buildToolImage(tool),
                                        if (tool.isAvailable != true)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.3),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade700,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'Unavailable',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    tool.name ?? 'Unknown tool',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: tool.isAvailable == true ? null : Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '€${tool.dailyRate?.toStringAsFixed(2) ?? '0.00'}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const Text(
                                      ' / day',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      );
                    },
                    childCount: _recommendedTools.length,
                  ),
                ),
              )
            else
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No recommended tools',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
