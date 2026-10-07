import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muserpol_pvt/components/button.dart';
import 'package:muserpol_pvt/components/susessful.dart';
import 'package:muserpol_pvt/screens/list_services_menu/service_loader.dart';
import 'package:muserpol_pvt/screens/modal_enrolled/modal.dart';
import 'package:muserpol_pvt/services/service_method.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muserpol_pvt/bloc/user/user_bloc.dart';
import 'package:muserpol_pvt/components/dialog_action.dart';
import 'package:muserpol_pvt/screens/navigation_general_pages.dart';
import 'package:muserpol_pvt/screens/pages/menu.dart';
import 'package:muserpol_pvt/components/header_muserpol.dart';

import 'service_option.dart';
import 'tutorial_targets.dart';

class ScreenListService extends StatefulWidget {
  final bool showTutorial;
  const ScreenListService({super.key, required this.showTutorial});

  @override
  State<ScreenListService> createState() => _ScreenListServiceState();
}

class _ScreenListServiceState extends State<ScreenListService> {
  final GlobalKey keyMenuButton = GlobalKey();
  final GlobalKey keyComplemento = GlobalKey();
  final GlobalKey keyAportes = GlobalKey();
  final GlobalKey keyPrestamos = GlobalKey();
  final GlobalKey keyRetFundQuotaAid = GlobalKey();

  TutorialCoachMark? tutorialCoachMark;
  bool isGridView = false;
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    checkVersion(mounted, context);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final userBloc =
        BlocProvider.of<UserBloc>(context, listen: false).state.user;
    final isInitial = _loadingData;

    try {
      if (userBloc?.isEconomicComplement == true) {
        if (!mounted) return;
        await loadGeneralServicesComplementEconomic(context);
      }

      if (!mounted) return;
      await loadGeneralServices(context);
    } finally {
      if (isInitial && mounted) {
        setState(() => _loadingData = false);
      }
    }

    if (isInitial && widget.showTutorial && mounted &&
        await _shouldShowTutorial()) {
      _showTutorial();
    }
  }

  Future<bool> _shouldShowTutorial() async {
    final userBloc = BlocProvider.of<UserBloc>(context, listen: false).state.user;
    final tutorialKey = userBloc?.affiliateId != null
        ? 'tutorial_omited_${userBloc!.affiliateId}'
        : 'tutorial_omited';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(tutorialKey) == true) return false;
    return true;
  }

  Future<void> _markTutorialOmited() async {
    final userBloc = BlocProvider.of<UserBloc>(context, listen: false).state.user;
    final tutorialKey = userBloc?.affiliateId != null
        ? 'tutorial_omited_${userBloc!.affiliateId}'
        : 'tutorial_omited';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(tutorialKey, true);
  }

  void _showTutorial() {
    if (!mounted) return;
    tutorialCoachMark = TutorialCoachMark(
      targets: getTutorialTargets(
        keyMenuButton: keyMenuButton,
        keyComplemento: keyComplemento,
        keyAportes: keyAportes,
        keyPrestamos: keyPrestamos,
        keyRetFundQuotaAid: keyRetFundQuotaAid,
      ),
      colorShadow: const Color(0xff419388),
      textSkip: "OMITIR",
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 30,
      ),
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () => _markTutorialOmited(),
      onSkip: () {
        _markTutorialOmited();
        return true;
      },
    )..show(context: context);
  }

  void _closeTutorialIfActive() {
    if (tutorialCoachMark != null && tutorialCoachMark!.isShowing) {
      try {
        tutorialCoachMark!.skip();
      } catch (e) {
        debugPrint("Error cerrando tutorial: $e");
      }
    }
  }

  void _goToModule(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigatorBarGeneral(initialIndex: index),
      ),
    );
  }

  Future<bool?> _onBackPressed() async {
    return await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (_) => DialogTwoAction(
        message: '¿Estás seguro de salir de la aplicación MUSERPOL PVT?',
        actionCorrect: () => Navigator.of(context).pop(true),
        actionCancel: () => Navigator.of(context).pop(false),
        messageCorrect: 'Salir',
      ),
    );
  }

  @override
  void dispose() {
    _closeTutorialIfActive();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final services = <ServiceData>[
      ServiceData(
        key: keyComplemento,
        image: 'assets/images/icon_complement_economic.webp',
        title: 'Complemento Económico',
        description: 'Solicitud y seguimiento de trámites.',
        onPressed: () async {
          final userBloc =
              BlocProvider.of<UserBloc>(context, listen: false).state.user;

          if (userBloc?.isEconomicComplement == true) {
            if (userBloc?.enrolled == false) {
              return showBarModalBottomSheet(
                expand: false,
                enableDrag: false,
                isDismissible: false,
                context: context,
                builder: (contextModal) => ModalInsideModal(
                  nextScreen: (message) {
                    return showSuccessful(context, message, () async {
                      Navigator.pop(contextModal);
                      _goToModule(0);
                    });
                  },
                ),
              );
            } else {
              _goToModule(0);
            }
          } else {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext contextDialog) {
                return AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        size: 40,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Usted no es beneficiario, contactarse con la MUSERPOL',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ButtonComponent(
                        text: 'OK',
                        onPressed: () => Navigator.of(contextDialog).pop(),
                      )
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
      ServiceData(
        key: keyAportes,
        image: 'assets/images/icon_contributions.webp',
        title: 'Certificación de Aportes',
        description: 'Visualización de aportes sector activo y pasivo.',
        onPressed: () => _goToModule(1),
      ),
      ServiceData(
        key: keyPrestamos,
        image: 'assets/images/icon_loans.webp',
        title: 'Préstamos',
        description: 'Seguimiento de trámites y evaluación referencial.',
        onPressed: () => _goToModule(2),
      ),
      ServiceData(
        key: keyRetFundQuotaAid,
        image: 'assets/images/icon_retFund.png',
        title: 'Fondo de Retiro y Cuota Auxilio Mortuorio',
        description: 'Impresión de liquidaciones de fondo de retiro y cuota auxilio mortuorio.',
        onPressed: () => _goToModule(3),
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final exit = await _onBackPressed();
        if (exit == true) {
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        }
      },
      child: Scaffold(
        appBar: AppBarDualTitle(keyMenuButton: keyMenuButton),
        drawer: const MenuDrawer(),
        body: Stack(
          children: [
            CustomMaterialIndicator(
              onRefresh: () async {
                await _loadInitialData();
                await Future.delayed(const Duration(seconds: 2));
              },
              trigger: IndicatorTrigger.leadingEdge,
              triggerMode: IndicatorTriggerMode.onEdge,
              trailingScrollIndicatorVisible: false,
              notificationPredicate: (notification) => notification.depth == 0,
              backgroundColor: const Color(0xff419388),
              indicatorBuilder: (context, controller) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                );
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nuestros Servicios',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isGridView ? Icons.view_list : Icons.grid_view,
                        color: const Color(0xff419388),
                      ),
                      onPressed: () {
                        setState(() {
                          isGridView = !isGridView;
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              if (!isGridView) ...[
                for (final s in services)
                  ServiceOption(
                    key: s.key,
                    image: s.image,
                    title: s.title,
                    description: s.description,
                    onPressed: s.onPressed,
                  ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: services.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final s = services[index];
                      final isLastOdd =
                          services.length.isOdd && index == services.length - 1;

                      if (isLastOdd) {
                        return Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 2 - 32,
                            child: ServiceGridItem(
                              service: s,
                            ),
                          ),
                        );
                      }

                      return ServiceGridItem(service: s);
                    },
                  ),
                ),
              ],
              SizedBox(height: 20.h),
            ],
          ),
        ),
        if (_loadingData) _buildLoadingOverlay(),
      ],
      ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.35),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 24,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xff419388),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando tus datos...',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ServiceData {
  final Key key;
  final String image;
  final String title;
  final String description;
  final VoidCallback onPressed;

  ServiceData({
    required this.key,
    required this.image,
    required this.title,
    required this.description,
    required this.onPressed,
  });
}

class ServiceGridItem extends StatelessWidget {
  final ServiceData service;

  const ServiceGridItem({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const kPrimaryGreen = Color(0xff419388);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: service.onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xff2a4f49) : kPrimaryGreen,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
              color: Colors.black.withAlpha((0.25 * 255).toInt()),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Imagen en círculo semitransparente
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha((0.35 * 255).toInt()),
              ),
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                service.image,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            // Título sin fondo y letras claras
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                service.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
