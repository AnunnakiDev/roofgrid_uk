import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/custom_expansion_tile.dart';
import 'package:roofgrid_uk/widgets/header_widget.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  List<UserModel> _expiringUsers = [];
  bool _isLoadingUsers = true;
  bool _isAddingUser = false;
  String _searchQuery = '';
  String _searchField = 'Email'; // Default search field
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      _users = usersSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.role != UserRole.admin)
          .toList();

      // Filter users with expiring subscriptions (within 30 days)
      final now = DateTime.now();
      _expiringUsers = _users.where((user) {
        if (user.subscriptionEndDate == null) return false;
        final daysUntilExpiry =
            user.subscriptionEndDate!.difference(now).inDays;
        return user.isPro && daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
      }).toList();

      // Initialize filtered users
      _filteredUsers = List.from(_users);

      setState(() {
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
    }
  }

  Future<int> _fetchTileSubmissionCount(String userId) async {
    try {
      final tilesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tiles')
          .get();
      return tilesSnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _fetchCalculationCount(String userId) async {
    try {
      final calculationsSnapshot = await FirebaseFirestore.instance
          .collection('calculations')
          .where('userId', isEqualTo: userId)
          .get();
      return calculationsSnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _toggleProStatus(UserModel user, {int? days}) async {
    try {
      if (days != null) {
        // Promote to Pro with specified timeframe
        final subscriptionEndDate = DateTime.now().add(Duration(days: days));
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .update({
          'role': 'pro',
          'subscriptionEndDate': Timestamp.fromDate(subscriptionEndDate),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Demote to Free
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .update({
          'role': 'free',
          'subscriptionEndDate': null,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      await _fetchUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              days != null ? 'User promoted to Pro' : 'User demoted to Free'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user status: $e')),
      );
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    try {
      // Delete from Firebase Auth
      await FirebaseAuth.instance.currentUser?.delete();
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .delete();
      // Delete user's tiles subcollection
      final tilesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('tiles')
          .get();
      for (var doc in tilesSnapshot.docs) {
        await doc.reference.delete();
      }
      await _fetchUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    }
  }

  Future<void> _addUser(String email, String password) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final userId = userCredential.user?.uid;
      if (userId == null) throw Exception('Failed to create user');

      // Create user in Firestore
      final newUser = UserModel(
        id: userId,
        email: email,
        role: UserRole.free,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(newUser.toJson());

      await _fetchUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding user: $e')),
      );
    }
  }

  void _showAddUserDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password *',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                setState(() => _isAddingUser = true);
                await _addUser(emailController.text.trim(),
                    passwordController.text.trim());
                setState(() => _isAddingUser = false);
                Navigator.pop(context);
              }
            },
            child: _isAddingUser
                ? const CircularProgressIndicator()
                : const Text('Add User'),
          ),
        ],
      ),
    );
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (_searchQuery.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users.where((user) {
          final queryLower = _searchQuery.toLowerCase();
          switch (_searchField) {
            case 'Email':
              return user.email?.toLowerCase().contains(queryLower) ?? false;
            case 'Name':
              return user.displayName?.toLowerCase().contains(queryLower) ??
                  false;
            case 'Phone':
              return user.phone?.toLowerCase().contains(queryLower) ?? false;
            case 'Status':
              String status = user.isPro
                  ? 'pro'
                  : user.isTrialActive
                      ? 'trial'
                      : 'free';
              return status.toLowerCase().contains(queryLower);
            default:
              return false;
          }
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding =
        isLargeScreen ? const EdgeInsets.all(24.0) : const EdgeInsets.all(16.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddUserDialog,
            tooltip: 'Add New User',
          ),
        ],
      ),
      body: _isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HeaderWidget(title: 'Admin Dashboard: User Management'),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildExpiringSubscriptionsTile(),
                  const SizedBox(height: 16),
                  const Text(
                    'Users',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _filteredUsers.isEmpty
                      ? const Center(child: Text('No users found'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return _buildUserCard(user, index);
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return isSmallScreen
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by $_searchField',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                              _filterUsers('');
                            });
                          },
                          tooltip: 'Clear search',
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                ),
                onChanged: _filterUsers,
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _searchField,
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    _searchField = value!;
                    _searchQuery = '';
                    _searchController.clear();
                    _filterUsers('');
                  });
                },
                items: ['Email', 'Name', 'Phone', 'Status']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by $_searchField',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                                _filterUsers('');
                              });
                            },
                            tooltip: 'Clear search',
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                  onChanged: _filterUsers,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _searchField,
                onChanged: (value) {
                  setState(() {
                    _searchField = value!;
                    _searchQuery = '';
                    _searchController.clear();
                    _filterUsers('');
                  });
                },
                items: ['Email', 'Name', 'Phone', 'Status']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          );
  }

  Widget _buildExpiringSubscriptionsTile() {
    if (_expiringUsers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: CustomExpansionTile(
        title: Text(
          'Expiring Subscriptions (${_expiringUsers.length})',
        ),
        subtitle: const Text(
          'Users with Pro subscriptions expiring within 30 days',
          style: TextStyle(fontSize: 12),
        ),
        children: _expiringUsers.asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;
          return _buildUserCard(user, index);
        }).toList(),
      ),
    );
  }

  Widget _buildUserCard(UserModel user, int index) {
    return FutureBuilder<Map<String, int>>(
      future: Future.wait([
        _fetchTileSubmissionCount(user.id),
        _fetchCalculationCount(user.id),
      ]).then((results) => {
            'tileCount': results[0],
            'calculationCount': results[1],
          }),
      builder: (context, snapshot) {
        final tileCount = snapshot.data?['tileCount'] ?? 0;
        final calculationCount = snapshot.data?['calculationCount'] ?? 0;

        Color statusColor;
        String statusText;
        if (user.isPro) {
          statusColor = Colors.green;
          statusText = 'Pro';
        } else if (user.isTrialActive) {
          statusColor = Colors.blue;
          statusText = 'Trial';
        } else {
          statusColor = Colors.grey;
          statusText = 'Free';
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(2, 2),
              ),
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: CustomExpansionTile(
            leading: user.profileImage != null && user.profileImage!.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: NetworkImage(user.profileImage!),
                    radius: 24,
                  )
                : CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    radius: 24,
                    child: Text(
                      user.displayName?.isNotEmpty == true
                          ? user.displayName![0].toUpperCase()
                          : user.email![0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
            title: Text(
              user.email ?? 'No Email',
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    user.isPro ? Icons.star : Icons.star_border,
                    color: user.isPro ? Colors.green : Colors.grey,
                  ),
                  onPressed: () {
                    if (user.isPro) {
                      _toggleProStatus(user);
                    } else {
                      _showPromoteOptions(user);
                    }
                  },
                  tooltip: user.isPro ? 'Downgrade to Free' : 'Upgrade to Pro',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteUser(user),
                  tooltip: 'Delete User',
                ),
              ],
            ),
            animationIndex: index,
            children: [
              _infoRow('User ID', user.id),
              if (user.displayName != null)
                _infoRow('Display Name', user.displayName!),
              if (user.phone != null) _infoRow('Phone', user.phone!),
              _infoRow(
                  'Membership',
                  user.isPro
                      ? 'Pro'
                      : user.isTrialActive
                          ? 'Trial'
                          : 'Free'),
              if (user.isTrialActive)
                _infoRow(
                    'Trial Start',
                    user.proTrialStartDate != null
                        ? DateFormat('dd MMMM yyyy')
                            .format(user.proTrialStartDate!)
                        : 'N/A'),
              if (user.isTrialActive)
                _infoRow(
                    'Trial End',
                    user.proTrialEndDate != null
                        ? DateFormat('dd MMMM yyyy')
                            .format(user.proTrialEndDate!)
                        : 'N/A'),
              if (user.isSubscribed)
                _infoRow(
                    'Subscription End',
                    user.subscriptionEndDate != null
                        ? DateFormat('dd MMMM yyyy')
                            .format(user.subscriptionEndDate!)
                        : 'N/A'),
              _infoRow('Created At',
                  DateFormat('dd MMMM yyyy').format(user.createdAt)),
              if (user.lastLoginAt != null)
                _infoRow('Last Login',
                    DateFormat('dd MMMM yyyy').format(user.lastLoginAt!)),
              const SizedBox(height: 16),
              Text(
                'Usage History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              _infoRow('Tiles Submitted', tileCount.toString()),
              _infoRow(
                  'Calculations Performed',
                  calculationCount == 0
                      ? 'Not Available'
                      : calculationCount.toString()),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showPromoteOptions(UserModel user) {
    final durations = [
      14,
      30,
      60,
      90,
      120,
      150,
      180,
      210,
      240,
      270,
      300,
      330,
      360
    ];
    final durationLabels = [
      '14 Days',
      '1 Month',
      '2 Months',
      '3 Months',
      '4 Months',
      '5 Months',
      '6 Months',
      '7 Months',
      '8 Months',
      '9 Months',
      '10 Months',
      '11 Months',
      '12 Months'
    ];
    int selectedIndex = 0;

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: 300,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Promote to Pro',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: durations.length,
                    builder: (context, index) => Center(
                      child: Text(
                        durationLabels[index],
                        style: TextStyle(
                          fontSize: 16,
                          color: index == selectedIndex
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          fontWeight: index == selectedIndex
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _toggleProStatus(user, days: durations[selectedIndex]);
                      Navigator.pop(context);
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text(
          'Are you sure you want to delete "${user.email}"? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUser(user);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
