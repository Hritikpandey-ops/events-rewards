// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/news_provider.dart';
import '../../core/models/news_model.dart';

class CreateNewsScreen extends StatefulWidget {
  final NewsModel? newsToEdit;
  
  const CreateNewsScreen({super.key, this.newsToEdit});

  @override
  _CreateNewsScreenState createState() => _CreateNewsScreenState();
}

class _CreateNewsScreenState extends State<CreateNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _summaryController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _categoryController = TextEditingController();
  
  // Category options
  final List<String> _categories = [
    'Business',
    'Sports', 
    'Technology',
    'Health',
    'Entertainment',
    'Politics',
    'Education',
    'Science',
    'Other'
  ];
  
  String? _selectedCategory;
  bool _isPublished = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing an existing news
    if (widget.newsToEdit != null) {
      _titleController.text = widget.newsToEdit!.title;
      _contentController.text = widget.newsToEdit!.content;
      _summaryController.text = widget.newsToEdit!.summary ?? '';
      _imageUrlController.text = widget.newsToEdit!.imageUrl ?? '';
      _selectedCategory = widget.newsToEdit!.category;
      _isPublished = widget.newsToEdit!.isPublished;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.newsToEdit != null ? 'Edit News' : 'Create News'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Consumer<NewsProvider>(
        builder: (context, newsProvider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Banner Image Section
                _buildBannerSection(theme),
                const SizedBox(height: 24),
                
                // News Title
                _buildFormField(
                  controller: _titleController,
                  label: 'News Title',
                  icon: Icons.title,
                  validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                
                // Category Dropdown
                _buildCategoryDropdown(theme),
                const SizedBox(height: 16),
                
                // Summary
                _buildFormField(
                  controller: _summaryController,
                  label: 'Summary (Optional)',
                  icon: Icons.summarize,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                // Content
                _buildFormField(
                  controller: _contentController,
                  label: 'Content',
                  icon: Icons.article,
                  maxLines: 8,
                  validator: (value) => value?.isEmpty ?? true ? 'Content is required' : null,
                ),
                const SizedBox(height: 16),
                
                // Image URL
                _buildFormField(
                  controller: _imageUrlController,
                  label: 'Image URL (Optional)',
                  icon: Icons.image,
                ),
                const SizedBox(height: 16),
                
                // Publication Status Section
                _buildPublicationSection(theme),
                const SizedBox(height: 32),
                
                // Create/Update Button
                _buildActionButton(newsProvider, theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBannerSection(ThemeData theme) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.7),
            theme.colorScheme.primary.withOpacity(0.4),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 48,
            color: theme.colorScheme.onPrimary.withOpacity(0.8),
          ),
          const SizedBox(height: 8),
          Text(
            widget.newsToEdit != null ? 'Edit News Image' : 'Add News Image',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.newsToEdit != null) ...[
            const SizedBox(height: 8),
            Text(
              'Current news image',
              style: TextStyle(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      items: _categories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCategory = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  Widget _buildPublicationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Publication Status',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _isPublished ? Icons.publish : Icons.drafts,
                color: _isPublished ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPublished ? 'Publish Now' : 'Save as Draft',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _isPublished 
                          ? 'Your news will be visible to everyone'
                          : 'Your news will be saved as draft',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isPublished,
                onChanged: (value) {
                  setState(() {
                    _isPublished = value;
                  });
                },
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(NewsProvider newsProvider, ThemeData theme) {
    return ElevatedButton(
      onPressed: newsProvider.isLoading ? null : _handleNewsAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: newsProvider.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Text(
              widget.newsToEdit != null ? 'Update News' : 'Create News',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Future<void> _handleNewsAction() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final newsProvider = Provider.of<NewsProvider>(context, listen: false);

    bool success;
    if (widget.newsToEdit != null) {
      // Update existing news
      success = await newsProvider.updateNews(
        newsId: widget.newsToEdit!.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        summary: _summaryController.text.trim().isEmpty ? null : _summaryController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        category: _selectedCategory,
        isPublished: _isPublished,
      );
    } else {
      // Create new news
      success = await newsProvider.createNews(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        summary: _summaryController.text.trim().isEmpty ? null : _summaryController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        category: _selectedCategory,
        isPublished: _isPublished,
      );
    }

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.newsToEdit != null
                ? 'News updated successfully!'
                : 'News created successfully!'
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.newsToEdit != null
                ? 'Failed to update news'
                : 'Failed to create news'
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _summaryController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
