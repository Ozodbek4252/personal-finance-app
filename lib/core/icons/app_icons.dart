// Line icons copied from the "Personal Finance App" design.
// All icons use a 24x24 view box and are drawn with strokes only.
// Draw them with the AppIcon widget.

/// The inner SVG shapes of one icon.
final class AppIconData {
  const AppIconData(this.svgBody);

  final String svgBody;
}

abstract final class AppIcons {
  static const close = AppIconData('<path d="M6 6l12 12M18 6L6 18"/>');
  static const chevronDown = AppIconData('<path d="M6 9l6 6 6-6"/>');
  static const calendar = AppIconData(
    '<rect x="3.5" y="5" width="17" height="15.5" rx="2"/><path d="M3.5 10h17M8 3v4M16 3v4"/>',
  );
  static const card = AppIconData(
    '<rect x="2.5" y="5.5" width="19" height="13" rx="2"/><path d="M2.5 10h19M6 15h4"/>',
  );
  static const pencil = AppIconData(
    '<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13.5 6.5l4 4"/>',
  );
  static const paperclip = AppIconData(
    '<path d="M20 11.5l-8 8a5 5 0 0 1-7-7l8.5-8.5a3.3 3.3 0 0 1 4.7 4.7L9.7 17.2a1.7 1.7 0 0 1-2.4-2.4L15 7"/>',
  );
  static const car = AppIconData(
    '<path d="M3 13l2-5a2 2 0 0 1 1.9-1.4h10.2A2 2 0 0 1 19 8l2 5v4a1 1 0 0 1-1 1h-1M5 18H4a1 1 0 0 1-1-1v-4h18M9 18h6"/><circle cx="7" cy="17.5" r="1.7"/><circle cx="17" cy="17.5" r="1.7"/>',
  );
  static const cart = AppIconData(
    '<circle cx="9" cy="20" r="1.3"/><circle cx="18" cy="20" r="1.3"/><path d="M2.5 3.5h2.6l2.3 11.2a1.5 1.5 0 0 0 1.5 1.3h8.7a1.5 1.5 0 0 0 1.5-1.2L20.5 8H6.2"/>',
  );
  static const food = AppIconData(
    '<path d="M7 3v8M4.5 3v5a2.5 2.5 0 0 0 5 0V3M7 11v10M17 21V3c-2.2 1.2-3.5 3.6-3.5 7v3.5H17"/>',
  );
  static const bag = AppIconData(
    '<path d="M5.5 8h13l-1 12.5h-11z"/><path d="M9 10V6.5a3 3 0 0 1 6 0V10"/>',
  );
  static const receipt = AppIconData(
    '<path d="M6 3h12v18l-3-1.8-3 1.8-3-1.8-3 1.8z"/><path d="M9 8h6M9 12h6M9 16h3"/>',
  );
  static const heart = AppIconData(
    '<path d="M12 20s-7.5-4.4-7.5-10a4.2 4.2 0 0 1 7.5-2.6A4.2 4.2 0 0 1 19.5 10c0 5.6-7.5 10-7.5 10z"/><path d="M8 12.5h2.2l1.3-2 1.6 4 1.2-2H16"/>',
  );
  static const cap = AppIconData(
    '<path d="M2.5 9L12 4.5 21.5 9 12 13.5z"/><path d="M6.5 11v4.5c0 1.5 2.5 3 5.5 3s5.5-1.5 5.5-3V11M21.5 9v5"/>',
  );
  static const alert = AppIconData(
    '<path d="M12 4l9 16H3z"/><path d="M12 10v4.5M12 17.3v.2"/>',
  );
  static const box = AppIconData(
    '<path d="M3.5 7.5L12 3.5l8.5 4v9L12 20.5l-8.5-4z"/><path d="M3.5 7.5L12 11.5l8.5-4M12 11.5v9"/>',
  );
  static const plus = AppIconData('<path d="M12 5v14M5 12h14"/>');
  static const backspace = AppIconData(
    '<path d="M9 5.5h11a1 1 0 0 1 1 1v11a1 1 0 0 1-1 1H9l-6-6.5z"/><path d="M12.5 9.5l5 5M17.5 9.5l-5 5"/>',
  );
  static const bank = AppIconData(
    '<path d="M3 9.5L12 4.5l9 5M4.5 9.5v8M9 9.5v8M15 9.5v8M19.5 9.5v8M3 20h18"/>',
  );
  static const wallet = AppIconData(
    '<path d="M4 7.5A2.5 2.5 0 0 1 6.5 5H18v2.5"/><rect x="4" y="7.5" width="16.5" height="12" rx="2"/><path d="M16 13.5h1.5"/>',
  );
  static const cash = AppIconData(
    '<rect x="2.5" y="6" width="19" height="12" rx="2"/><circle cx="12" cy="12" r="2.6"/><path d="M6 9.5v.01M18 14.5v.01"/>',
  );
  static const star = AppIconData(
    '<path d="M12 3.8l2.5 5.1 5.6.8-4 4 .9 5.6L12 16.6l-5 2.7.9-5.6-4-4 5.6-.8z"/>',
  );
  static const laptop = AppIconData(
    '<rect x="4.5" y="5" width="15" height="10.5" rx="1.5"/><path d="M2.5 19h19"/>',
  );
  static const gift = AppIconData(
    '<rect x="3.5" y="8.5" width="17" height="4" rx="1"/><path d="M5 12.5V20h14v-7.5M12 8.5V20M12 8.5C10.5 5 7 5 7 7s3 1.5 5 1.5zM12 8.5c1.5-3.5 5-3.5 5-1.5s-3 1.5-5 1.5z"/>',
  );
  static const chevronLeft = AppIconData('<path d="M15 6l-6 6 6 6"/>');
  static const info = AppIconData(
    '<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5M12 8v.01"/>',
  );
  static const dragHandle = AppIconData(
    '<path d="M9 6.5h.01M15 6.5h.01M9 12h.01M15 12h.01M9 17.5h.01M15 17.5h.01"/>',
  );
  static const home = AppIconData(
    '<path d="M3.5 10.5L12 4l8.5 6.5"/><path d="M5.5 9v11h13V9"/><path d="M10 20v-5h4v5"/>',
  );
  static const film = AppIconData(
    '<rect x="3.5" y="5" width="17" height="14" rx="2"/><path d="M7.5 5v14M16.5 5v14M3.5 9.5h4M3.5 14.5h4M16.5 9.5h4M16.5 14.5h4"/>',
  );
  static const dumbbell = AppIconData(
    '<path d="M6.5 6.5v11M17.5 6.5v11M3.5 9v6M20.5 9v6M6.5 12h11"/>',
  );
  static const coffee = AppIconData(
    '<path d="M4.5 9h12v5.5a5 5 0 0 1-5 5h-2a5 5 0 0 1-5-5z"/><path d="M16.5 10.5h1.5a2.5 2.5 0 0 1 0 5h-1.8M8 3.5v2.5M12 3.5v2.5"/>',
  );
  static const shirt = AppIconData(
    '<path d="M8.5 4L4 6.5 5.5 11l2-1V20h9v-10l2 1L20 6.5 15.5 4a3.5 3.5 0 0 1-7 0z"/>',
  );
  static const fuel = AppIconData(
    '<path d="M4.5 20V5.5A1.5 1.5 0 0 1 6 4h6a1.5 1.5 0 0 1 1.5 1.5V20M3 20h12M4.5 10.5h9M13.5 8.5l3 0 2 2V17a1.5 1.5 0 0 0 3 0V9l-3-3"/>',
  );
  static const phone = AppIconData(
    '<rect x="6.5" y="3" width="11" height="18" rx="2.2"/><path d="M10.5 18h3"/>',
  );
  static const plane = AppIconData(
    '<path d="M3 13.5l7-2 3.5-7.5c.4-.8 1.8-.6 1.8.3L14 11l5.5 1.5a1.5 1.5 0 0 1 0 3L14 14l1 4.5-2 1-3-4.5-7-1.5z"/>',
  );
  static const paw = AppIconData(
    '<circle cx="7" cy="10" r="1.8"/><circle cx="17" cy="10" r="1.8"/><circle cx="10" cy="6" r="1.8"/><circle cx="14" cy="6" r="1.8"/><path d="M12 12c-2.8 0-5 3.5-5 5.5 0 1.5 1.3 2 2.5 2 1 0 1.6-.5 2.5-.5s1.5.5 2.5.5c1.2 0 2.5-.5 2.5-2 0-2-2.2-5.5-5-5.5z"/>',
  );
  static const users = AppIconData(
    '<circle cx="9" cy="8.5" r="3.2"/><path d="M3 19.5c.8-3 3.2-4.5 6-4.5s5.2 1.5 6 4.5M16 5.6a3.2 3.2 0 0 1 0 5.8M18 15.3c1.5.6 2.6 2 3 4.2"/>',
  );
  static const wrench = AppIconData(
    '<path d="M14.5 6.5a4 4 0 0 0 5 5l-8.5 8.5a2.1 2.1 0 0 1-3-3l8.5-8.5a4 4 0 0 1 5-5l-2.5 2.5.5 2 2 .5z"/>',
  );
  static const check = AppIconData('<path d="M5 12.5l4.5 4.5L19 7"/>');
  static const search = AppIconData(
    '<circle cx="11" cy="11" r="6.5"/><path d="M20 20l-4.2-4.2"/>',
  );
  static const eye = AppIconData(
    '<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z"/><circle cx="12" cy="12" r="2.8"/>',
  );
  static const arrowDownLeft = AppIconData(
    '<path d="M17 7L7 17M15.5 17H7V8.5"/>',
  );
  static const trendUp = AppIconData('<path d="M3 17l6-6 4 4 8-8M15 7h6v6"/>');
  static const arrowUpRight = AppIconData(
    '<path d="M7 17L17 7M8.5 7H17v8.5"/>',
  );
  static const trendDown = AppIconData(
    '<path d="M3 7l6 6 4-4 8 8M15 17h6v-6"/>',
  );
  static const coins = AppIconData(
    '<circle cx="9" cy="9" r="5.5"/><path d="M14.5 9.6a5.5 5.5 0 1 1-4.9 8.9"/>',
  );
  static const chevronRight = AppIconData('<path d="M9 6l6 6-6 6"/>');
  static const list = AppIconData(
    '<path d="M8.5 6.5h11M8.5 12h11M8.5 17.5h11M4.5 6.5h.01M4.5 12h.01M4.5 17.5h.01"/>',
  );
  static const chart = AppIconData(
    '<path d="M5 20v-7M12 20V5M19 20v-10M3 20h18"/>',
  );
  static const settings = AppIconData(
    '<circle cx="12" cy="12" r="3"/><path d="M19.4 13.5l1.6 1.2-1.8 3.2-1.9-.7a7.5 7.5 0 0 1-1.7 1l-.3 2h-3.6l-.3-2a7.5 7.5 0 0 1-1.7-1l-1.9.7L3 14.7l1.6-1.2a7.6 7.6 0 0 1 0-2L3 10.3l1.8-3.2 1.9.7a7.5 7.5 0 0 1 1.7-1l.3-2h3.6l.3 2a7.5 7.5 0 0 1 1.7 1l1.9-.7 1.8 3.2-1.6 1.2a7.6 7.6 0 0 1 0 2z"/>',
  );
  static const trash = AppIconData(
    '<path d="M4 7h16M9 7V4.5h6V7M6.5 7l1 13h9l1-13M10 11v5M14 11v5"/>',
  );
  static const copy = AppIconData(
    '<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V5.5A1.5 1.5 0 0 0 14.5 4h-9A1.5 1.5 0 0 0 4 5.5v9A1.5 1.5 0 0 0 5.5 16H8"/>',
  );
  static const inbox = AppIconData(
    '<path d="M3.5 13.5l2.5-8h12l2.5 8V19a1 1 0 0 1-1 1h-15a1 1 0 0 1-1-1z"/><path d="M3.5 13.5h5l1 2h5l1-2h5"/>',
  );

  /// Two opposite arrows (⇄): exchanges between so'm and dollars.
  static const exchange = AppIconData('<path d="M4 8h15l-4-4M20 16H5l4 4"/>');
  static const sort = AppIconData(
    '<path d="M7 4v16M3.5 16.5L7 20l3.5-3.5M17 20V4M13.5 7.5L17 4l3.5 3.5"/>',
  );
  static const filter = AppIconData(
    '<path d="M4 7h10M18 7h2M4 17h4M12 17h8"/><circle cx="16" cy="7" r="2"/><circle cx="10" cy="17" r="2"/>',
  );
  static const hash = AppIconData(
    '<path d="M5 9h14M5 15h14M10 4l-2 16M16 4l-2 16"/>',
  );
  static const globe = AppIconData(
    '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.5 2.5 3.5 5.5 3.5 8.5s-1 6-3.5 8.5c-2.5-2.5-3.5-5.5-3.5-8.5s1-6 3.5-8.5z"/>',
  );
  static const lock = AppIconData(
    '<rect x="5" y="10.5" width="14" height="10" rx="2"/><path d="M8 10.5V7.5a4 4 0 0 1 8 0v3"/>',
  );
  static const download = AppIconData(
    '<path d="M12 4v11M7 10.5l5 5 5-5M4.5 20h15"/>',
  );
  static const cloud = AppIconData(
    '<path d="M7 18.5a4.5 4.5 0 0 1-.5-9A6 6 0 0 1 18 8.5a4 4 0 0 1-.5 10z"/>',
  );
  static const eyeOff = AppIconData(
    '<path d="M3 3l18 18"/><path d="M10.6 5.6c.5-.1.9-.1 1.4-.1 6 0 9.5 6.5 9.5 6.5a17 17 0 0 1-2.7 3.4M6.6 6.6C3.9 8.3 2.5 12 2.5 12S6 18.5 12 18.5c1.8 0 3.3-.5 4.6-1.2"/><path d="M10 10a2.8 2.8 0 0 0 4 4"/>',
  );

  /// Icons a user can pick for a category, in the design's order.
  /// The keys are stored in the database.
  static const categoryIcons = <String, AppIconData>{
    'dumbbell': dumbbell,
    'car': car,
    'cart': cart,
    'food': food,
    'coffee': coffee,
    'bag': bag,
    'shirt': shirt,
    'receipt': receipt,
    'home': home,
    'fuel': fuel,
    'phone': phone,
    'film': film,
    'heart': heart,
    'cap': cap,
    'plane': plane,
    'paw': paw,
    'users': users,
    'gift': gift,
    'wrench': wrench,
    'laptop': laptop,
    'wallet': wallet,
    'star': star,
    'alert': alert,
    'box': box,
  };

  /// Every icon by name. Used by the design preview page.
  static const all = <String, AppIconData>{
    'close': close,
    'exchange': exchange,
    'chevronDown': chevronDown,
    'calendar': calendar,
    'card': card,
    'pencil': pencil,
    'paperclip': paperclip,
    'car': car,
    'cart': cart,
    'food': food,
    'bag': bag,
    'receipt': receipt,
    'heart': heart,
    'cap': cap,
    'alert': alert,
    'box': box,
    'plus': plus,
    'backspace': backspace,
    'bank': bank,
    'wallet': wallet,
    'cash': cash,
    'star': star,
    'laptop': laptop,
    'gift': gift,
    'chevronLeft': chevronLeft,
    'info': info,
    'dragHandle': dragHandle,
    'home': home,
    'film': film,
    'dumbbell': dumbbell,
    'coffee': coffee,
    'shirt': shirt,
    'fuel': fuel,
    'phone': phone,
    'plane': plane,
    'paw': paw,
    'users': users,
    'wrench': wrench,
    'check': check,
    'search': search,
    'eye': eye,
    'arrowDownLeft': arrowDownLeft,
    'trendUp': trendUp,
    'arrowUpRight': arrowUpRight,
    'trendDown': trendDown,
    'coins': coins,
    'chevronRight': chevronRight,
    'list': list,
    'chart': chart,
    'settings': settings,
    'trash': trash,
    'copy': copy,
    'inbox': inbox,
    'sort': sort,
    'filter': filter,
    'hash': hash,
    'globe': globe,
    'lock': lock,
    'download': download,
    'cloud': cloud,
    'eyeOff': eyeOff,
  };
}
