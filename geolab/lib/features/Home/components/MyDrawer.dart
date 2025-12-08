import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_state.dart';
import 'package:geolab/features/Auth/Bloc/auth_event.dart';
import 'package:geolab/Service/subscription_service.dart';
import 'package:geolab/models/subscription_model.dart';
import 'package:geolab/features/Settings/SettingsPage.dart';
import 'package:geolab/Service/api_service.dart';
import 'package:geolab/models/prediction_model.dart';
import 'package:geolab/utils/app_localizations.dart';
import 'package:geolab/utils/rtl_wrapper.dart';
import 'package:geolab/Service/theme_service.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:geolab/features/Home/components/ClassificationResultModal.dart';
import 'package:geolab/features/Home/components/ShimmerLoading.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_state.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  final ScrollController _scrollController = ScrollController();
  final List<PredictionModel> _history = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _limit = 10;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200 && // Load when near bottom
        !_isLoadingMore && 
        _hasMore) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await ApiService().getMyPredictions(page: 1, limit: _limit);
      if (mounted) {
        setState(() {
          _history.clear();
          _history.addAll(items);
          _hasMore = items.length >= _limit;
          _currentPage = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final items = await ApiService().getMyPredictions(page: nextPage, limit: _limit);
      
      if (mounted) {
        setState(() {
          if (items.isNotEmpty) {
            _history.addAll(items);
            _currentPage = nextPage;
            _hasMore = items.length >= _limit;
          } else {
            _hasMore = false;
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Don't show full error screen for load more, maybe snackbar?
          // keeping silent or simple log for now to avoid disrupting UX
          _isLoadingMore = false;
        });
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return RTLWrapper(
          child: AlertDialog(
            title: Text(context.t('auth.logout.confirm')),
            content: Text(context.t('auth.logout.confirmMessage')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.t('common.cancel')),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  // Dispatch logout
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
                child: Text(
                  context.t('auth.logout.title'),
                  style: TextStyle(color: ThemeService.instance.errorColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return RTLWrapper(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(HugeIcons.strokeRoundedSetting06),
                  title: Text(context.t('navigation.settings')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ));
                  },
                ),
                ListTile(
                  leading: Icon(HugeIcons.strokeRoundedLogout01,
                      color: ThemeService.instance.errorColor),
                  title: Text(
                    context.t('auth.logout.title'),
                    style: TextStyle(color: ThemeService.instance.errorColor),
                  ),
                  onTap: () => _showLogoutConfirmation(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;
    return RTLWrapper(
      child: Drawer(
        backgroundColor: themeService.surfaceColor,
        child: Column(
          children: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                String displayName = context.t('settings.profile.userName');
                String displayEmail = context.t('settings.profile.userEmail');
                if (authState is AuthAuthenticated) {
                  final email = authState.user.email;
                  if (email.isNotEmpty) {
                    displayEmail = email;
                    displayName = authState.user.name ?? (email.split('@').first);
                  }
                }

                return UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: themeService.primaryColor),
                  accountName: Text(
                    displayName,
                    style: TextStyle(color: themeService.onPrimaryColor),
                  ),
                  accountEmail: Text(
                    displayEmail,
                    style: TextStyle(color: themeService.onPrimaryColor.withOpacity(0.7)),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: themeService.primaryColor.withOpacity(0.3),
                    child: Icon(HugeIcons.strokeRoundedUserQuestion01,
                        color: themeService.onPrimaryColor, size: 40),
                  ),
                  otherAccountsPictures: [
                    IconButton(
                      icon: Icon(HugeIcons.strokeRoundedAccountSetting01,
                          color: themeService.onPrimaryColor, size: 30),
                      onPressed: () => _showBottomSheet(context),
                    ),
                  ],
                );
              },
            ),
            // Usage summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: FutureBuilder<SubscriptionModel>(
                future: SubscriptionService().getSubscriptionStatus(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final sub = snapshot.data!;
                  final used = sub.requestCount;
                  final total = sub.dailyLimit;
                  final pct = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
                  return Container(
                    decoration: BoxDecoration(
                      color: themeService.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(context.t('common.usage'), style: Theme.of(context).textTheme.bodyLarge),
                            Text('${used}/${total}')
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(value: pct),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // History list
            Expanded(
              child: _isLoading 
                ? const SidebarShimmerPlaceholder()
                : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.t('common.errorHistory'),
                              style: TextStyle(color: themeService.errorColor, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: _loadInitialData,
                              child: Text(context.t('common.retry'), style: TextStyle(color: themeService.primaryColor)),
                            )
                          ],
                        ),
                      ),
                    )
                  : _history.isEmpty
                    ? Center(
                        child: Text(
                          context.t('navigation.historyEmpty'),
                          style: TextStyle(color: themeService.textColor.withOpacity(0.6)),
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _history.length + (_isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index == _history.length) {
                             return const Padding(
                               padding: EdgeInsets.all(16.0),
                               child: Center(
                                 child: SizedBox(
                                   width: 24, 
                                   height: 24, 
                                   child: CircularProgressIndicator(strokeWidth: 2)
                                 )
                               ),
                             );
                          }
                          
                          final p = _history[index];
                          return ListTile(
                            leading: const Icon(HugeIcons.strokeRoundedTime04),
                            title: Text(p.prediction),
                            subtitle: Text('${p.confidencePercentage} • ${p.timestamp.toLocal()}'),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: themeService.surfaceColor,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (context) => ClassificationResultModal(
                                  state: ClassificationComplete(
                                    rockType: p.prediction,
                                    confidence: p.confidence,
                                    image: null,
                                    additionalData: {
                                      'xai_visualization': p.xaiVisualization,
                                      'image_url': p.imagePath,
                                      'probabilities': p.probabilities,
                                      'confidence_breakdown': p.confidenceBreakdown,
                                      'reasoning': p.reasoning,
                                      'stage1': p.stage1,
                                      'stage2': p.stage2,
                                      'stage3': p.stage3,
                                    },
                                  ),
                                  themeService: themeService,
                                ),
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
