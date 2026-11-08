/// Normalizza gli URL delle immagini note tramite il proxy Supabase TEST.
/// La funzione resta indipendente da main.dart così i widget riutilizzabili
/// possono usarla senza dipendenze circolari.
String valoraImageProxyUrl(String rawUrl) {
  final value = rawUrl.trim();
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https') return value;
  const proxyHosts = {
    'bandai-a.akamaihd.net', 'www.gunpla-italia.com', 'cdn.media.amplience.net',
    'www.hasbropulse.com', 'tf.takaratomy.co.jp', 'www.hasbro.com',
    'www.fantamagus.com', 'www.gamelife.it', 'kurogami.com', 'www.kurogami.com',
    'www.vendiloshop.it', 'cdn.rebrickable.com', 'bits-and-blocks.co.uk',
    'www.brickeconomy.com', 'i5.walmartimages.com', 'shopdeinerd.com', 'm3toys.com',
    'eshop.czechrepubrick.cz', 'www.lego.com', 'images.pristineauction.com',
    'super-briques.fr', 'instructions.hasbro.com', 'bwtf.com', 'www.bwtf.com',
    'media.entertainmentearth.com', 'collecticontoys.com', 'images.brickset.com',
    'funko.com', 'www.funko.com', 'tamashiiweb.com', 'www.ibs.it',
    'www.thechosenprime.com', 'transforverse.eu', 'cdn11.bigcommerce.com',
    'www.lafeltrinelli.it', 'www.tfsafari.com', 'i.tformers.com', 'i.ebayimg.com',
    's3.amazonaws.com', 'toynado.ca', 'www.1999.co.jp', 'images.bigbadtoystore.com',
    'pops.today', 'images-na.ssl-images-amazon.com', 'www.previewsworld.com',
    'cdn.awsli.com.br', 'image.shopcraft.co.kr', 'b2c.magicpressedizioni.it',
    'media.karousell.com', 'comicsbox.it', 'www.bibelotmania.com',
    'thelittlebrickmarket.com', 'www.comicsbox.it', 'books.google.com',
    'down-id.img.susercontent.com', 'giuntialpunto.it', 'www.hlj.com',
    'cdn.ecommercedns.uk', 'media.gamestop.com', 'i0.wp.com', 'www.comix21.it',
    'edicolaonline.store', 'smoothsales.com.au', 'resources.claroshop.com',
    'toyarena.com', 'cmdstore.com', 'rihappy.vtexassets.com', 'transformers.pe',
    'media.okini.land', 'www.toynk.com', 'www.fanboycollectibles.com',
    'imgmarketplace.lojasrenner.com.br', 'kaostech.net', 'indemandtoys.co.uk',
    'brickheads.co', 'atlbrick.com', 'www.transformerland.com', 'cdn.shopify.com',
  };
  if (!proxyHosts.contains(uri.host.toLowerCase())) return value;
  const supabaseUrl = 'https://eeiekkflpnkummxtvljy.supabase.co';
  return '$supabaseUrl/functions/v1/collection-image-proxy?url=${Uri.encodeComponent(value)}';
}
