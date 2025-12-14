import 'package:flutter/material.dart';
import 'package:darkord/consts/app_constants.dart';
import 'package:darkord/models/user.dart';
import 'package:darkord/api/api_service.dart';
import 'package:darkord/widgets/common_widgets.dart';
import 'package:provider/provider.dart';
import 'package:darkord/api/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
class UserProfilePage extends StatefulWidget {
  final String userId;
  final String accessToken;
  
  const UserProfilePage(
      {super.key, required this.userId, required this.accessToken});
  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}
class _UserProfilePageState extends State<UserProfilePage> {
  late Future<User> _futureUser;
  final _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    _futureUser = _fetchUserData();
    print(_futureUser);
  }
  Future<User> _fetchUserData() async {
    return await _apiService.fetchUsers(widget.accessToken, widget.userId);
  }
  void _refreshProfile() {
    setState(() {
      _futureUser = _fetchUserData();
    });
  }
  Future<void> _showImageSourceDialog(User user) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Change Profile Picture',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery, user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text(
                  'Take a Photo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera, user);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ],
        );
      },
    );
  }
  Future<void> _pickAndUploadImage(ImageSource source, User user) async {
    try {
      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile == null) {
        return; // User cancelled
      }
      // Get file info
      final File imageFile = File(pickedFile.path);
      final int fileSize = await imageFile.length();
      final String fileExtension = pickedFile.path.split('.').last.toLowerCase();
      // Validate file size (max 256 KB)
      if (fileSize > 262144) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image too large. Please choose an image under 256 KB.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      // Step 1: Get pre-signed upload URL
      final uploadUrlData = await _apiService.getAvatarUploadUrl(
        user.userId,
        file_ext: fileExtension,
        file_size: fileSize,
      );
      // Step 2: Upload to S3
      final uploadMethod = uploadUrlData['method'] as String; // GET method from API
      final uploadUri = uploadUrlData['uri'] as String;
      final uploadHeaders = uploadUrlData['headers'] as Map<String, dynamic>;
      print('Upload method: $uploadMethod');
      print('Upload URI: $uploadUri');
      print('Upload headers: $uploadHeaders');
      // Read file bytes
      final bytes = await imageFile.readAsBytes();
      // Upload to S3 using the method specified by the API
      http.Response uploadResponse;
      
      if (uploadMethod.toUpperCase() == 'PUT') {
        uploadResponse = await http.put(
          Uri.parse(uploadUri),
          headers: uploadHeaders.map((key, value) => MapEntry(key, value.toString())),
          body: bytes,
        );
      } else if (uploadMethod.toUpperCase() == 'POST') {
        uploadResponse = await http.post(
          Uri.parse(uploadUri),
          headers: uploadHeaders.map((key, value) => MapEntry(key, value.toString())),
          body: bytes,
        );
      } else {
        throw Exception('Unsupported upload method: $uploadMethod');
      }
      print('Upload response status: ${uploadResponse.statusCode}');
      print('Upload response body: ${uploadResponse.body}');
      if (!mounted) return;
      
      // Close loading
      Navigator.pop(context);
      if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 204) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Refresh profile to show new avatar
        _refreshProfile();
      } else {
        throw Exception('Upload failed with status: ${uploadResponse.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      
      // Close loading if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile picture: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  Future<void> _showEditAboutMeDialog(User user) async {
    final TextEditingController controller = TextEditingController(text: user.aboutMe);
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Edit About Me',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            maxLength: 150,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tell us about yourself...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateAboutMe(user.userId, controller.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
  Future<void> _updateAboutMe(String userId, String newAboutMe) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    try {
      await _apiService.updateUser(
        userId,
        about_me: newAboutMe,
      );
      if (!mounted) return;
      
      // Close loading indicator
      Navigator.pop(context);
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('About Me updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      // Refresh the profile
      _refreshProfile();
    } catch (e) {
      if (!mounted) return;
      
      // Close loading indicator
      Navigator.pop(context);
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update About Me: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.mainBGColor,
      appBar: AppBar(
        backgroundColor: AppConstants.mainBGColor,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<User>(
        future: _futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading profile...');
          } else if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Error',
              subtitle: 'Error: ${snapshot.error}',
            );
          } else if (!snapshot.hasData) {
            return const EmptyState(
              icon: Icons.person_off,
              title: 'No user data found',
              subtitle: 'Unable to load profile information',
            );
          }
          final user = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile picture with status indicator and camera button
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[800]!,
                          width: 2,
                        ),
                        image: user.avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(user.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: user.avatarUrl == null
                            ? Colors.grey
                            : null,
                      ),
                      child: user.avatarUrl == null
                          ? const Icon(Icons.person,
                              size: 70, color: Colors.white)
                          : null,
                    ),
                    // Status indicator with Discord-style icons
                    Positioned(
                      bottom: 0,
                      right: 30,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppConstants.mainBGColor,
                            width: 3,
                          ),
                        ),
                        child: _buildStatusIcon(user.status ?? 'invisible', 24),
                      ),
                    ),
                    // Camera button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showImageSourceDialog(user),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppConstants.mainBGColor,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Username
                Text(
                  user.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Edit Profile button
                const SizedBox(height: 16),
                // ElevatedButton(
                //   onPressed: () {
                //     // TODO: Implement edit profile functionality
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.grey[800],
                //     foregroundColor: Colors.white,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(20),
                //     ),
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 16,
                //       vertical: 8,
                //     ),
                //   ),
                //   child: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       const Text('Edit Profile'),
                //       const SizedBox(width: 4),
                //       Icon(Icons.edit, 
                //           size: 16, 
                //           color: const Color.fromARGB(255, 54, 188, 255)), // Green pencil icon
                //     ],
                //   ),
                // ),
                const SizedBox(height: 24),
                // Email section
                _buildProfileSection(
                  icon: Icons.email,
                  title: 'Email',
                  value: user.emailAddr,
                  showCopy: true,
                ),
                const SizedBox(height: 16),
                // User ID section
                _buildProfileSection(
                  icon: Icons.person,
                  title: 'User ID',
                  value: 'ID: ${user.userId}',
                  showCopy: false,
                ),
                const SizedBox(height: 32),
                // About me section
                Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About Me',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.aboutMe.isEmpty ? 'No bio yet' : user.aboutMe,
                              style: TextStyle(
                                color: user.aboutMe.isEmpty ? Colors.grey : Colors.white,
                                fontSize: 16,
                                fontStyle: user.aboutMe.isEmpty ? FontStyle.italic : FontStyle.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, 
                            color: Colors.blue, size: 20),
                        onPressed: () => _showEditAboutMeDialog(user),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  Widget _buildProfileSection({
    required IconData icon,
    required String title,
    required String value,
    required bool showCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (showCopy)
            IconButton(
              icon: const Icon(Icons.content_copy, color: Colors.grey),
              onPressed: () {
                // Copy to clipboard functionality
              },
            ),
        ],
      ),
    );
  }

  // Build status icon widget (Discord-style)
  Widget _buildStatusIcon(String status, double size) {
    switch (status.toLowerCase()) {
      case 'online':
        // Green circle for online
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        );
      case 'idle':
        // Hollow circle with small filled segment for idle
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer orange circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            // Inner hollow part (creates ring effect)
            Container(
              width: size * 0.65,
              height: size * 0.65,
              decoration: BoxDecoration(
                color: AppConstants.mainBGColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      case 'do_not_disturb':
      case 'dnd':
        // Circle with minus sign for do not disturb
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: size * 0.6,
              height: size * 0.15,
              decoration: BoxDecoration(
                color: AppConstants.mainBGColor,
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
            ),
          ],
        );
      case 'invisible':
      case 'offline':
        // Grey outline circle for invisible
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey, width: size * 0.15),
          ),
        );
      default:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}

