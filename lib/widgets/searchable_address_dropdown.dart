import 'package:flutter/material.dart';
import '../models/address.dart';

typedef OnAddressSelected = void Function(String customerName);

class SearchableAddressDropdown extends StatefulWidget {
  final List<Address> addresses;
  final String? selectedName;
  final OnAddressSelected onSelected;
  final String hintText;

  const SearchableAddressDropdown({
    Key? key,
    required this.addresses,
    required this.onSelected,
    this.selectedName,
    this.hintText = 'Select customer',
  }) : super(key: key);

  @override
  _SearchableAddressDropdownState createState() => _SearchableAddressDropdownState();
}

class _SearchableAddressDropdownState extends State<SearchableAddressDropdown> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSearchModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.selectedName == null || widget.selectedName!.isEmpty
                    ? widget.hintText
                    : widget.selectedName!,
                style: TextStyle(
                  fontSize: 14,
                  color: widget.selectedName == null || widget.selectedName!.isEmpty
                      ? Colors.grey
                      : Colors.black,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
          ],
        ),
      ),
    );
  }

  void _openSearchModal(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return _AddressSearchModal(addresses: widget.addresses);
      },
    );

    if (selected != null) widget.onSelected(selected);
  }
}

class _AddressSearchModal extends StatefulWidget {
  final List<Address> addresses;
  const _AddressSearchModal({Key? key, required this.addresses}) : super(key: key);

  @override
  __AddressSearchModalState createState() => __AddressSearchModalState();
}

class __AddressSearchModalState extends State<_AddressSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  late List<Address> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.addresses;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = widget.addresses;
      } else {
        _filtered = widget.addresses.where((a) {
          return a.customerName.toLowerCase().contains(q) ||
              a.address1.toLowerCase().contains(q) ||
              a.address2.toLowerCase().contains(q) ||
              a.address3.toLowerCase().contains(q) ||
              a.address4.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.75;
    return SafeArea(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search customer or address',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('No results'))
                  : ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, idx) {
                  final a = _filtered[idx];
                  return ListTile(
                    title: Text(a.customerName),
                    // subtitle: Text(_composeAddressPreview(a)),
                    onTap: () => Navigator.of(context).pop(a.customerName),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  //
  // String _composeAddressPreview(Address a) {
  //   final parts = <String>[];
  //   if (a.address1.isNotEmpty && a.address1 != 'N/A') parts.add(a.address1);
  //   if (a.address2.isNotEmpty && a.address2 != 'N/A') parts.add(a.address2);
  //   if (a.address3.isNotEmpty && a.address3 != 'N/A') parts.add(a.address3);
  //   if (a.address4.isNotEmpty && a.address4 != 'N/A') parts.add(a.address4);
  //   return parts.join(', ');
  // }
}
