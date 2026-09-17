import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/bay_job.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../../shared/widgets/statement_modal_helper.dart';
import '../../home/widgets/action_confirmation_card.dart';
import '../widgets/job_card.dart';
import '../widgets/new_job_modal.dart';
import '../../navigation/widgets/drawer_helper.dart';

enum JobFilter { allActive, waiting, readyForPickup, completed }

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  JobFilter _filter = JobFilter.allActive;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<GarageRepository>();
    final locale = context.watch<AppLocale>();

    // Calculate metrics
    final allJobs = repo.bayJobs;
    final waitingJobs = allJobs.where((j) => j.isWaiting).toList();
    final readyJobs = allJobs.where((j) => j.isReadyForPickup).toList();
    final activeJobs = allJobs.where((j) => !j.isCompleted).toList();
    final completedJobs = allJobs.where((j) => j.isCompleted).toList();

    // Filter jobs based on selected filter and search query
    List<BayJob> displayedJobs;
    switch (_filter) {
      case JobFilter.allActive:
        displayedJobs = List.from(activeJobs);
        break;
      case JobFilter.waiting:
        displayedJobs = List.from(waitingJobs);
        break;
      case JobFilter.readyForPickup:
        displayedJobs = List.from(readyJobs);
        break;
      case JobFilter.completed:
        displayedJobs = List.from(completedJobs);
        break;
    }

    // Sort newest first
    displayedJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Filter by search query if any
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      displayedJobs = displayedJobs.where((j) {
        return j.customerName.toLowerCase().contains(q) ||
            j.vehicleModel.toLowerCase().contains(q) ||
            j.plateNumber.toLowerCase().contains(q) ||
            j.bayNumber.toLowerCase().contains(q) ||
            j.customerPhone.contains(q);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      drawer: buildAppDrawer(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                iconSize: 24,
                tooltip: 'Back',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => Navigator.of(context).pop(),
              )
            : buildDrawerHamburgerButton(context),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.build_circle_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.isBangla ? 'চলতি কাজ ও বে' : 'Jobs & Active Bays',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${activeJobs.length} ${locale.isBangla ? 'টি কাজ চলমান' : 'active jobs'} • ${waitingJobs.length} ${locale.isBangla ? 'অপেক্ষমান' : 'waiting'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: AppColors.textPrimary),
            tooltip: locale.isBangla ? 'বে ও কাজের তালিকা প্রিন্ট' : 'Print Jobs & Bays Sheet',
            onPressed: () => _showJobsSheetModal(context, repo, displayedJobs, locale),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Divider(height: 1.5, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          // 5-second Undo Bar (Destructive / State Change Undo Window)
          if (repo.lastUndoAction != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ActionConfirmationCard(
                title: repo.lastUndoAction!.title,
                description: repo.lastUndoAction!.description,
                countdownSeconds: repo.undoCountdown,
                onUndo: () => repo.undoLastAction(),
              ),
            ),
          ],

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top Prominent 54px Action Button: + Open New Job
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.add_task_rounded, size: 22),
                    label: Text(
                      locale.isBangla ? '+ নতুন কাজ শুরু করুন' : '+ Open New Job',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    onPressed: () => NewJobModal.show(context),
                  ),
                ),
                const SizedBox(height: 16),

                // KPI Mini Summary Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: locale.isBangla ? 'মোট এক্টিভ' : 'Active',
                        count: activeJobs.length,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.08),
                        icon: Icons.car_repair_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        title: locale.isBangla ? 'অপেক্ষমান' : 'Waiting',
                        count: waitingJobs.length,
                        color: AppColors.warning,
                        bgColor: const Color(0xFFFEF3C7),
                        icon: Icons.hourglass_top_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        title: locale.isBangla ? 'প্রস্তুত' : 'Ready',
                        count: readyJobs.length,
                        color: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFE0F2FE),
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: locale.isBangla
                          ? 'কাস্টমার, গাড়ি, নম্বর প্লেট খুঁজুন...'
                          : 'Search customer, vehicle, plate, or bay...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Filter Tabs / Chips Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: locale.isBangla ? 'চলতি ()' : 'All Active ()',
                        filter: JobFilter.allActive,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: locale.isBangla ? 'অপেক্ষমান ()' : 'Waiting ()',
                        filter: JobFilter.waiting,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: locale.isBangla ? 'প্রস্তুত ()' : 'Ready for Pickup ()',
                        filter: JobFilter.readyForPickup,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: locale.isBangla ? 'সম্পন্ন ()' : 'Completed ()',
                        filter: JobFilter.completed,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // List of Job Cards or Empty State
                if (displayedJobs.isEmpty)
                  _buildEmptyState(context, locale)
                else
                  ...displayedJobs.map((job) => JobCard(job: job)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required JobFilter filter,
  }) {
    final isSelected = _filter == filter;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filter = filter;
          });
        }
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocale locale) {
    final bool isSearch = _searchQuery.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isSearch ? AppColors.background : AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSearch ? AppColors.border : AppColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              isSearch ? Icons.search_off_rounded : Icons.car_repair_rounded,
              size: 34,
              color: isSearch ? AppColors.textSecondary : AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch
                ? (locale.isBangla ? 'কোন কাজ পাওয়া যায়নি' : 'No matching jobs found')
                : (locale.isBangla ? 'কোন সক্রিয় কাজের কার্ড নেই' : 'No Active Job Cards'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearch
                ? (locale.isBangla ? 'অনুসন্ধানের শব্দ পরিবর্তন করে আবার চেষ্টা করুন' : 'Try searching with a different name or number')
                : (locale.isBangla ? 'গাড়ি মেরামত ও বে অ্যাসাইন করতে নতুন কাজ খুলুন।' : 'Create a job card to register a vehicle and assign a workshop bay.'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          if (isSearch)
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              child: Text(locale.isBangla ? 'ফিল্টার মুছুন' : 'Clear Search Filter'),
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_task_rounded, size: 18),
              label: Text(
                locale.isBangla ? 'নতুন কাজ খুলুন' : 'Open New Job',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              onPressed: () => NewJobModal.show(context),
            ),
        ],
      ),
    );
  }

  void _showJobsSheetModal(
    BuildContext context,
    GarageRepository repo,
    List<BayJob> jobs,
    AppLocale locale,
  ) {
    final currency = context.read<CurrencyManager>();
    final profile = repo.workshopProfile;
    final workshopName = repo.getWorkshopName();
    final address = profile['address'] ?? '';
    final phone = profile['phone'] ?? '';
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final sb = StringBuffer();
    sb.writeln('========================================');
    sb.writeln(workshopName.toUpperCase());
    if (address.isNotEmpty) sb.writeln(address);
    if (phone.isNotEmpty) sb.writeln('Phone: $phone');
    sb.writeln('========================================');
    sb.writeln('WORKSHOP ACTIVE BAYS & JOBS SHEET');
    sb.writeln('Date & Time: $nowStr');
    sb.writeln('Total Jobs Listed: ${jobs.length}');
    sb.writeln('----------------------------------------');

    if (jobs.isEmpty) {
      sb.writeln('No active jobs found in this view.');
    } else {
      for (int i = 0; i < jobs.length; i++) {
        final j = jobs[i];
        final cost = j.isCompleted ? (j.settledAmount ?? j.estimatedCost) : j.estimatedCost;
        sb.writeln('${i + 1}. [${j.bayNumber}] ${j.customerName}');
        if (j.vehicleModel.isNotEmpty || j.plateNumber.isNotEmpty) {
          sb.writeln('   Vehicle: ${j.vehicleModel} ${j.plateNumber.isNotEmpty ? '(${j.plateNumber})' : ''}');
        }
        sb.writeln('   Task: ${j.taskDescription}');
        sb.writeln('   Status: ${j.status.toUpperCase()} | Amount: ${currency.format(cost)}');
        if (j.technicianName.isNotEmpty) {
          sb.writeln('   Tech: ${j.technicianName}');
        }
        sb.writeln('');
      }
    }
    sb.writeln('========================================');
    sb.writeln('End of Workshop Sheet');

    final plainText = sb.toString();

    StatementModalHelper.show(
      context: context,
      title: locale.isBangla ? 'বে ও কাজের বিবরণী' : 'Active Bays Workshop Sheet',
      subtitle: '${jobs.length} ${locale.isBangla ? 'টি কাজ অন্তর্ভুক্ত' : 'jobs listed'}',
      textStatement: plainText,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  locale.isBangla ? 'তালিকায় মোট কাজ' : 'Total Jobs in Sheet',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                ),
                Text(
                  '${jobs.length}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (jobs.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Text(
                locale.isBangla ? 'কোন কাজ পাওয়া যায়নি' : 'No jobs in current filter',
                style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            )
          else
            ...jobs.map((j) {
              final cost = j.isCompleted ? (j.settledAmount ?? j.estimatedCost) : j.estimatedCost;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        j.bayNumber,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            j.customerName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          if (j.vehicleModel.isNotEmpty || j.plateNumber.isNotEmpty)
                            Text(
                              [if (j.vehicleModel.isNotEmpty) j.vehicleModel, if (j.plateNumber.isNotEmpty) j.plateNumber].join(' • '),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          Text(
                            j.taskDescription,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currency.format(cost),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
