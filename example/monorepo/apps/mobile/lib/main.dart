import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:models/models.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeutronX Monorepo Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ProductDto> products = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    
    try {
      // Call NeutronX backend
      final response = await http.get(
        Uri.parse('http://localhost:3000/products'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final productsList = data['products'] as List;
        
        // Parse using shared DTOs
        setState(() {
          products = productsList
              .map((json) => ProductDto.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading products: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('NeutronX Monorepo Demo'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(
                  child: Text('Start the backend: cd apps/backend && dart run'),
                )
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(product.description),
                      trailing: Text('\$${product.price.toStringAsFixed(2)}'),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadProducts,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
