// Instacart deep link configuration
const String instacartDeepLinkScheme = 'instacart://';
const String instacartWebUrl = 'https://www.instacart.com';

String buildInstacartCartUrl(List<String> items) {
  // TODO: Implement Instacart cart URL building
  // Format: instacart://cart?items=item1,item2,item3
  return '$instacartDeepLinkScheme?items=${items.join(',')}';
}
