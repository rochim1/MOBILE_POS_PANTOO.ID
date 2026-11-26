// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get promoValidating => 'Verifying promo code…';

  @override
  String get exitAppTitle => 'Exit the app?';

  @override
  String get exitAppMessage =>
      'Unsaved changes may be lost. Closing the app does not close the cashier shift or sign you out.';

  @override
  String get exitAppConfirm => 'Exit app';

  @override
  String get exitAppFailed => 'The app could not be closed. Please try again.';

  @override
  String get pendingCreditRecorded =>
      'Order recorded as a receivable. Continue collecting payment from Customer Receivables.';

  @override
  String get creditSaleRecorded => 'Credit sale recorded';

  @override
  String get creditSalePending =>
      'Not paid in full. The balance is saved as a customer receivable.';

  @override
  String get heldCartRestoreConfirm =>
      'Save the current cart before opening the saved order? Its items and customer will be kept.';

  @override
  String get heldCartSaveAndOpen => 'Save and open';

  @override
  String get heldCartNotEmpty =>
      'Save or clear the current cart before opening a saved order.';

  @override
  String get heldCartOtherStore =>
      'This saved order belongs to another store. Open its original store to continue.';

  @override
  String get heldCartRestoreFailed =>
      'Unable to open the saved order. Your cart is safe; try again.';

  @override
  String get cashierActionFailed => 'Action could not be completed';

  @override
  String get personalProfileInvalidPhoto => 'Invalid photo';

  @override
  String get personalProfileInvalidPhotoContent =>
      'The photo file does not contain a valid image';

  @override
  String get personalProfileInvalidPhotoPath => 'Invalid photo location';

  @override
  String get personalProfileUploadError => 'Photo upload failed';

  @override
  String get personalProfileTitle => 'Active cashier profile';

  @override
  String get personalProfileScope =>
      'Personal details of the PIN-verified cashier. Permissions, outlet and PIN stay unchanged.';

  @override
  String get personalProfileCached =>
      'Showing the last saved details. Connect to the internet to edit your profile.';

  @override
  String get personalProfilePhotoChange => 'Change profile photo';

  @override
  String get personalProfilePhotoRemove => 'Remove photo';

  @override
  String get personalProfilePhotoFormats => 'JPG, PNG or WebP. Up to 5 MB.';

  @override
  String get personalProfileIdentityReadOnly =>
      'Login details can only be changed through account security settings.';

  @override
  String get personalProfileSave => 'Save profile';

  @override
  String get personalProfileSaved => 'Profile updated successfully';

  @override
  String get personalProfileUnavailable => 'Unable to load your profile';

  @override
  String get personalProfilePickFailed =>
      'Unable to select a photo. Please try again.';

  @override
  String get personalProfileEmptyPhoto => 'The photo file is empty';

  @override
  String get personalProfilePhotoSize => 'Photos must be no larger than 5 MB';

  @override
  String get personalProfilePhotoType => 'Use a JPG, PNG or WebP photo';

  @override
  String get personalProfileInvalidInput =>
      'Name, phone number or address is invalid';

  @override
  String get personalProfilePhotoConflict =>
      'Choose either upload or remove photo, not both';

  @override
  String get personalProfileUploadFailed =>
      'Photo upload failed. Check your connection and try again.';

  @override
  String get personalProfileServerFailed =>
      'Unable to save or load your profile. Please try again.';

  @override
  String get personalProfileVersionConflict =>
      'Your profile has changed. Reload it before saving.';

  @override
  String get personalProfileReload => 'Reload profile';

  @override
  String get personalProfileInvalidSession => 'The cashier session is invalid';

  @override
  String get personalProfileNoSession => 'The cashier session is unavailable';

  @override
  String get personalProfileNotFound => 'Cashier profile not found';

  @override
  String get personalProfileServerValidation =>
      'Name, phone number, address or photo choice is invalid';

  @override
  String get setupAutomaticContextHelp =>
      'Your first store and stock location are created automatically. Next, add products or services. Other settings can wait.';

  @override
  String get setupBusinessLogo => 'Business logo';

  @override
  String get setupChooseBusinessLogo => 'Choose business logo';

  @override
  String get setupBusinessLogoFormats =>
      'Optional · JPG, PNG, WebP · up to 5 MB';

  @override
  String get setupRemainingRequiredSteps =>
      'Complete the remaining required steps.';

  @override
  String pos3f03891fda02(String arg1) {
    return '\nBatch $arg1';
  }

  @override
  String pos79a590570387(String arg1) {
    return '\nActual cost: $arg1';
  }

  @override
  String get posc0a010e50551 => '\nOriginal journal entry not yet confirmed';

  @override
  String pos0c9675bd9841(String arg1) {
    return '\nOriginal journal entry failed: $arg1';
  }

  @override
  String get pos879ea9b51bd7 => '\nReversal journal entry not yet confirmed';

  @override
  String pos8cff67795cb5(String arg1) {
    return '\nReversal journal entry failed: $arg1';
  }

  @override
  String posa350f080167b(String arg1) {
    return '\nBy $arg1';
  }

  @override
  String pos661046b05cc9(String arg1) {
    return '   Notes: $arg1';
  }

  @override
  String get pos5ce2b951d32d => '   and   ';

  @override
  String pos1234901f1561(String arg1, String arg2, String arg3) {
    return '   $arg1 $arg2 x $arg3';
  }

  @override
  String posde5e5ed2b7ae(String arg1) {
    return '  •  $arg1';
  }

  @override
  String pos94fb179f2344(String arg1) {
    return ' (HTTP $arg1)';
  }

  @override
  String posc9744dc328f8(String arg1) {
    return ' · Batch $arg1';
  }

  @override
  String pos9bf490502e78(String arg1, String arg2) {
    return ' · Deposit $arg1 ($arg2)';
  }

  @override
  String posb34c43522da4(String arg1) {
    return ' · Delivery note $arg1';
  }

  @override
  String posc5d767f22ec6(String arg1) {
    return ' · $arg1';
  }

  @override
  String pos97ed94c3c5d4(String arg1) {
    return ' · $arg1 days';
  }

  @override
  String pos7b27157c8a92(String arg1) {
    return ' • Batch $arg1';
  }

  @override
  String posf5cb1d63d91e(String arg1, String arg2) {
    return ' • estimated capacity $arg1 $arg2';
  }

  @override
  String posd1ebf6ed0dad(String arg1) {
    return ' • oldest $arg1';
  }

  @override
  String posd672f388af0f(String arg1) {
    return ' • $arg1';
  }

  @override
  String posb7e0b518ea55(String arg1) {
    return ' • $arg1 require review';
  }

  @override
  String pos4f22066d96ef(String arg1) {
    return '(Max $arg1)';
  }

  @override
  String get poscff2156d208d => '08xxxxxxxxxx';

  @override
  String pos732cde583b07(String arg1) {
    return '1 x $arg1';
  }

  @override
  String pos87d507a0208a(String arg1, String arg2, String arg3) {
    return '1 $arg1 = $arg2 $arg3';
  }

  @override
  String get pos37bddcbf7945 => '1. Find a purchase';

  @override
  String get pos7f7b7b3be96c => '1. Source purchase';

  @override
  String get pos0e33a2321322 => 'Top 10 Reports';

  @override
  String pos178f405d8376(String arg1) {
    return '2 x $arg1';
  }

  @override
  String get posa88673e1998a => '2. Location and items';

  @override
  String get posda2461dc4c65 => '3. Reason and resolution';

  @override
  String get pos5e3c05aa8fbd => '30 Days';

  @override
  String get pos50bbea57f4d0 => 'Last 30 Days';

  @override
  String get pos921b024be4b6 => '7 Days';

  @override
  String get pos0127a34dfd2c => 'Last 7 Days';

  @override
  String get pos1dc3ae18814b => 'last 7 days';

  @override
  String get pos19d8d271d250 => '90 Days';

  @override
  String get pos92727baf6571 => 'Last 90 Days';

  @override
  String get poscd4a252704cd => '< 1 minute';

  @override
  String pos5e6481728b57(String arg1) {
    return '@ Rp $arg1';
  }

  @override
  String get pos5273abffc139 => 'TRANSACTION ACTIONS';

  @override
  String get pos331ac1a57f89 => 'ASSETS & VEHICLES';

  @override
  String get pos966864740106 =>
      'Some payment confirmations are pending, even if the invoice is fully paid. Do not collect payment twice.';

  @override
  String get pos36b7fb4f9a18 =>
      'A payment confirmation is pending. Data is locked; resubmit the same proof to check the result without a duplicate payment.';

  @override
  String get pos883a34a40b54 => 'Order notes available';

  @override
  String get pos7fb591c94502 =>
      'Some items are being prepared. A supervisor PIN is required.';

  @override
  String get pos606436971add => 'Any shipping or actual costs?';

  @override
  String get pos4d064726954a => 'Advanced';

  @override
  String get pos86d441c226b4 => 'Submit';

  @override
  String get pos87fff599644e => 'Request Down Payment';

  @override
  String get pos3bca9769e24e => 'Submit discrepancy report';

  @override
  String get pose735cbe9effc => 'Request down payment';

  @override
  String get pos92f75e2f1650 => 'Submit return?';

  @override
  String get posd3dd70b0a951 => 'End operations';

  @override
  String get pos62d21681eda3 => 'Pantoo accent';

  @override
  String get pose0c6ee4c156d => 'Secure Access';

  @override
  String get pos44defb18e533 => 'Cashier Access';

  @override
  String get posef38073448c4 => 'Table management access denied';

  @override
  String get pos218c9c023e46 => 'Access all sales history';

  @override
  String get posde1781be836c => 'Stock access unavailable';

  @override
  String get pos6aa3a3956cf0 => 'Access unavailable';

  @override
  String get pos60ad46d8cab9 => 'Actions';

  @override
  String get pos0a4f2e3013a4 => 'Document actions';

  @override
  String get posf50f867d9136 =>
      'This action changes stock balances and may create journal entries automatically. Check the item details first.';

  @override
  String posca97584f1ff6(String arg1, String arg2) {
    return 'Unsupported inventory action: $arg1/$arg2';
  }

  @override
  String get pose3f2d8d7197d => 'More actions';

  @override
  String get posd94c0defdd67 => 'Receiving actions';

  @override
  String get pos8ecb75f58601 => 'Return actions';

  @override
  String get posaae7d1621479 =>
      'This action is unavailable for your permissions or the latest transfer status.';

  @override
  String get pos14c9ff04273c => 'Transaction actions';

  @override
  String get pos843e4fd9a436 => 'Unknown transfer action';

  @override
  String get pos89f29d42adb5 => 'Active';

  @override
  String get posd11f4d838612 => 'Available after changing the status to Member';

  @override
  String get pos7a87cdf85a9f => 'Enabled for cashier receipt printing';

  @override
  String get pos523105d6e126 => 'Enable Kitchen Flow in POS Settings first.';

  @override
  String get pos377c77dbfc01 => 'Enable POS Lock';

  @override
  String get pos7336fe1bc5d3 => 'Enable in POS';

  @override
  String get posb4e26befba24 => 'Enable Tables / Rooms in POS Settings first.';

  @override
  String get pos507d126a7d6c => 'Enable only the features your business uses.';

  @override
  String get pos2e61131b1e2f => 'Activate sales location';

  @override
  String get posdfae3bd5850b => 'Activate at least one store to manage tables.';

  @override
  String get pos2df503f82de0 =>
      'Enable this option to link the warehouse to a POS store.';

  @override
  String get pos3825003df1e3 =>
      'Activate the store and ensure the cashier uses the correct POS profile.';

  @override
  String get pos078d204bd918 => 'Enable for sales';

  @override
  String get pos5ba3752e3e30 => 'Daily Sales Activity';

  @override
  String get posffcd7fbae331 => 'Account';

  @override
  String get pos08af61f4a87c => 'Expense account';

  @override
  String get pos1cea339be731 => 'Account could not be created.';

  @override
  String get pos1f9c9c7c8f9e => 'This account does not have inventory access.';

  @override
  String get pos02081f30a5e0 =>
      'This account does not have permission to view the POS dashboard.';

  @override
  String get pos98007921829c =>
      'This account does not have permission to view the order queue.';

  @override
  String get pos3491bbe6c880 =>
      'This account does not have permission to submit approvals.';

  @override
  String get pose7a4c1367031 => 'Finance cash account';

  @override
  String get pos940234a21581 => 'Login account';

  @override
  String get posc94022120917 =>
      'This login account does not have a PIN. Create a PIN to continue.';

  @override
  String get posdc1e2531a28c => 'Asset Accounting';

  @override
  String get pos85b6ed5c3bd2 => 'Address';

  @override
  String get pos604bea5dda58 => 'Address *';

  @override
  String get posd1736799e06d =>
      'Local Wi-Fi address not found. Connect the POS phone to Wi-Fi or enable a hotspot.';

  @override
  String get pose23909414216 => 'Warehouse address *';

  @override
  String get pos50e596236aee =>
      'The warehouse address can be adjusted for this delivery.';

  @override
  String get posb9fa659409c6 => 'Customer\'s full address';

  @override
  String get pos24463a1bf4d2 => 'Manual address';

  @override
  String get pos6a93711c9632 => 'Shipping address';

  @override
  String get pos5b86b934d842 => 'Shipping address *';

  @override
  String pos7e9ed032cc32(String arg1) {
    return 'Address: $arg1';
  }

  @override
  String get pos3faa833b08be => 'Reason';

  @override
  String get posdfef2f134ef6 => 'Reason / notes (required)';

  @override
  String get pos64f19d7d9668 => 'Return Reason';

  @override
  String get posfd4eb9d469a4 => 'Reason for waste';

  @override
  String get poscebf83ae7585 => 'Disposal reason';

  @override
  String get pos915f1d3d6a09 => 'Correction reason *';

  @override
  String get posa1a64b6405f4 => 'Reason must be at least 3 characters';

  @override
  String get posbabdc64fb956 =>
      'A reason of at least 3 characters is required when there is a discrepancy.';

  @override
  String get posc99ab02e61b8 => 'Reason must be at least 3 characters.';

  @override
  String get posb759c899d5b0 => 'Cancellation reason';

  @override
  String get pos8dc82593c03b => 'Cancellation reason *';

  @override
  String get posa0299a19d99f => 'Cancellation reason is required';

  @override
  String get pos6368528ded87 => 'Deletion reason';

  @override
  String get pos5c2144140b4b => 'Sale reason';

  @override
  String get pos1a3a88c34341 => 'Rejection reason';

  @override
  String pos61cebd1cf6b2(String arg1) {
    return 'Rejection reason: $arg1';
  }

  @override
  String get pos9d0ca86850d6 => 'Closure reason and remaining items';

  @override
  String get pos2850a479c8f9 => 'Closure reason must be at least 8 characters.';

  @override
  String get pos102e192f9886 => 'Forced change reason';

  @override
  String get pos348e3ad43c94 => 'Return reason';

  @override
  String get pos876421b7949e => 'Discrepancy reason';

  @override
  String get posbe448d5c839b => 'Discrepancy reason (required)';

  @override
  String get posa17b7918dd15 => 'Discrepancy reason is required.';

  @override
  String posae638041fd8e(String arg1) {
    return 'Discrepancy reason: $arg1';
  }

  @override
  String get pos629480d7c6e4 => 'Reason not recorded';

  @override
  String posb8a08ba6e258(String arg1) {
    return 'Reason: $arg1';
  }

  @override
  String get pos0ef3120e77a1 => 'Cost allocation';

  @override
  String get pos934f80f88a89 => 'Automatic allocation';

  @override
  String get posf2acdb6020d7 => 'Automatically allocated on dispatch';

  @override
  String get posdbed1333c6ef =>
      'Alt+1 Dashboard · Alt+2 Cashier · Alt+3 Catalog';

  @override
  String get pos014cbca5ba87 =>
      'Alt+4 Orders & Tables · Alt+5 Inventory · Alt+6 History';

  @override
  String get pos0a18583acc03 => 'Transfer flow & details';

  @override
  String get pos6aa18e2874e9 =>
      'Historical flow not recorded; check the status and receipts.';

  @override
  String get pos74a8585178e3 => 'Preparation flow';

  @override
  String get posf4d4a3a1d79f => 'Store pickup';

  @override
  String get posa83f9555276d =>
      'You do not have an active shift in this store. Enter the opening cash amount to open a shift.';

  @override
  String get poscfdd6e8fddd5 =>
      'You do not have access to Active Orders & Tables.';

  @override
  String get posa7b14c35cb1f =>
      'You do not have permission to view active orders.';

  @override
  String get pos57fdd883599c =>
      'Android uses the selected Bluetooth thermal printer above. System/Wi-Fi printers are not used for cashier receipts.';

  @override
  String get pos93f2585ace2e => 'User-friendly interface';

  @override
  String get pos4163bd8e4931 => 'Production queue';

  @override
  String get pos642626eb2451 => 'Offline Transaction Queue';

  @override
  String get pos0e7c34e9ca53 => 'Could not load the queue';

  @override
  String get pos8656e7da87ba => 'Order queue / pick up later';

  @override
  String get posa48b31818805 => 'Transaction queue is empty';

  @override
  String get pos58dc6962b034 =>
      'Could not check the offline transaction queue. Data saved on this device will sync when this account signs in again. Sign out anyway?';

  @override
  String get posa29ec9f55015 => 'Kitchen production queue';

  @override
  String get posf7e5b5267754 => 'Are you sure you want to exit the app?';

  @override
  String posc2901f09b11d(String arg1) {
    return 'Are you sure you want to delete \"$arg1\"?';
  }

  @override
  String pos4a7f70cd767e(String arg1) {
    return 'Are you sure you want to delete product \"$arg1\"?';
  }

  @override
  String posf8ddd141364d(String arg1, String arg2) {
    return 'Are you sure you want to delete promotion \"$arg1\" ($arg2)?';
  }

  @override
  String get pos838dc4e298c6 => 'Online POS App';

  @override
  String get posc5fdea1d176c => 'Destination app unavailable. Receipt copied.';

  @override
  String get pos8cc047ac17d3 => 'Approval';

  @override
  String get pos41b81eb8db1b => 'Approved';

  @override
  String get posae94d90f653a => 'Approved via Mobile POS';

  @override
  String get pos05bd1eee56b8 => 'Place the barcode inside the frame';

  @override
  String get posd36df8019474 =>
      'Point your phone camera at the QR code to view the menu';

  @override
  String get pos0c52685ae7e2 => 'Point the camera at the product code';

  @override
  String get posbf8a40c438d0 => 'Area / Zone';

  @override
  String get poscc51a04a8901 => 'Display area';

  @override
  String get pos220120e6e34b =>
      'Transaction source; does not determine how the order is fulfilled';

  @override
  String pos57cdcf19a10a(String arg1, String arg2) {
    return 'Source: $arg1\nDestination: $arg2';
  }

  @override
  String get pos718d646d607a => 'Fixed Assets';

  @override
  String get pos29082e6724b4 => 'Insurance';

  @override
  String get posa514b2860c91 => 'Or enter a barcode / SKU';

  @override
  String get pos092d50eb5a8a => 'Set PIN';

  @override
  String get pos2037b252d5e0 => 'Configure Dashboard Widgets';

  @override
  String get pos385f6a96ab79 => 'Manage manual discounts and promo codes';

  @override
  String get pos62274222e3e3 =>
      'Set the order type, table, sales channel, customer, and price level.';

  @override
  String get pos8a4dc30ba939 => 'Set sales context';

  @override
  String get posaa3d8657bd92 => 'Set display location';

  @override
  String get posa1b06c99576a =>
      'Set a default receiving location in the Inventory Simple profile before receiving a PO.';

  @override
  String get pose993a43f1493 =>
      'Configure required customers, taxes, fees, rounding, and sales rules for your business.';

  @override
  String get pos23a638fc122e => 'Reset';

  @override
  String get posa77c960334e3 => 'Reset filters';

  @override
  String get pos6f7c8f3b4837 => 'Configure dashboard widgets';

  @override
  String get pos436b1c573119 => 'Discount Combination Rules';

  @override
  String get posceee0f5d9b4c => 'Dispatch rules';

  @override
  String get pos7cf89ee76e92 => 'HELP';

  @override
  String get poseaf71d6b1c79 => 'PAYMENT RECORD RECEIPT';

  @override
  String get posdda079aaa57c =>
      'The backend validates scrap permissions and accounts.';

  @override
  String get pose4a1e6e1f820 =>
      'An unencrypted database backup is still available. Manual recovery is required.';

  @override
  String get posafec631300bb => 'Share';

  @override
  String get pos10cfbdcd57a8 => 'Share Receipt';

  @override
  String get pos9abbb72a14c1 => 'Share as PDF';

  @override
  String get pos140852a655fd => 'Share as PNG';

  @override
  String get pose56f546cb66e => 'Share receipt via';

  @override
  String pos720eb19e66de(String arg1) {
    return 'Share receipt $arg1';
  }

  @override
  String get poseda849fb70be => 'Raw Materials';

  @override
  String get pos04f5b5ce0518 => 'Good';

  @override
  String get pos91f651c54514 => 'Items';

  @override
  String get pos8063497da7c9 => 'Item / code';

  @override
  String get pos950214d9b446 => 'Merchandise';

  @override
  String get pos77ea2d0a96a3 => 'Work in Progress';

  @override
  String get pos006fca52153a => 'PO items';

  @override
  String get pos35437e6347ba => 'Serialized items';

  @override
  String get pos938de32b04cc =>
      'Items will be removed from the cart, not from stock. The store and shift will then be checked again.';

  @override
  String get pos689b25ff156e => 'Returned items';

  @override
  String get pos9d3aa1c12691 => 'Received items';

  @override
  String get pos30351205ff4a => 'Lost items';

  @override
  String get posda515f4d210f => 'Damaged items';

  @override
  String get pos3d78f1b4c031 =>
      'Stock items are not available in the PO catalog. Select items manually.';

  @override
  String get posf4efcb605d73 => 'This item is already in the disposal list';

  @override
  String get pos91a68e9bf513 =>
      'Item already added. Edit the quantity in the list.';

  @override
  String get pos1900451e3409 => 'Item not found';

  @override
  String get pos024cd8937b2c => 'Item is not in the stocktake snapshot.';

  @override
  String get pos8e54dc5331b0 => 'Barcode';

  @override
  String get pos68699a00fc9d => 'Barcode not found at the source location';

  @override
  String get pos18f08eeb773c =>
      'Barcode not found in PO receipts at this location';

  @override
  String pos6385c5b0e840(String arg1) {
    return 'Barcode $arg1 not found';
  }

  @override
  String pos49b67ac0c655(String arg1) {
    return 'Barcode · $arg1';
  }

  @override
  String get poscbff89c30c54 => 'Line 3';

  @override
  String get poseee53cdc7cd8 => 'Line 4';

  @override
  String get pos5356cfdd73c3 => 'New';

  @override
  String pos0c1674e894ea(String arg1) {
    return 'New ($arg1)';
  }

  @override
  String get posaac8eb7439e8 => 'Just now';

  @override
  String get pos1433539c3b8f => 'Cancel';

  @override
  String get pos3432aed9b1cd => 'Cancel Purchase';

  @override
  String get posdbe47c83d4ca => 'Cancel';

  @override
  String get pos5b90d4ccc074 => 'Cancel Receipt';

  @override
  String get posa82ba1a88e58 => 'Cancel item';

  @override
  String get pos7f1262289c0d => 'Cancel payment';

  @override
  String get pos7b849f4abad8 => 'Cancel payment?';

  @override
  String get posa4babe595ba6 => 'Cancel order';

  @override
  String get pos4a4299234e5f => 'Cancel order?';

  @override
  String pos345a2afe9fe7(String arg1) {
    return 'Cancel $arg1?';
  }

  @override
  String get pos0059ce715aa6 => 'Usage Limit';

  @override
  String poscd4516ba1708(String arg1, String arg2, String arg3) {
    return 'Limit with $arg1% tolerance: $arg2 $arg3';
  }

  @override
  String get posaf8c680677bd =>
      'Per-customer limit (select a customer when applying the promotion)';

  @override
  String get pos8bf1ef5668b1 => 'Batch';

  @override
  String get pos518025a13256 => 'Batch & Expiry';

  @override
  String get pos007c04bae657 => 'Source batch *';

  @override
  String pos6f9650674671(String arg1) {
    return 'Batch $arg1';
  }

  @override
  String posf45b61e66113(String arg1, String arg2) {
    return 'Batch $arg1 · $arg2';
  }

  @override
  String posa2f8e389c7e3(String arg1, String arg2, String arg3) {
    return 'Batch $arg1 · $arg2 · $arg3';
  }

  @override
  String pos08ea63214a56(String arg1, String arg2, String arg3, String arg4) {
    return 'Batch $arg1 • $arg2 $arg3 • $arg4';
  }

  @override
  String get posb189a6911737 => 'Batch, expiry & notes';

  @override
  String pos19c47f48a246(String arg1, String arg2) {
    return 'Batch: $arg1 · $arg2';
  }

  @override
  String get posa74cc32718e6 => 'Takeaway';

  @override
  String get pos9fffab284d64 => 'Takeaway';

  @override
  String get pos6290c54f33d8 => 'Pay';

  @override
  String get pos2d38facc4bc6 => 'Pay Invoice';

  @override
  String get pos83553f81803a => 'Pay Now';

  @override
  String get pos7f4c8305af51 => 'Pay first';

  @override
  String get pos410df9b15672 => 'Pay for service';

  @override
  String get posdf6097e391d5 => 'Pay for order';

  @override
  String get pos28ee50878525 => 'Payment: CASH';

  @override
  String posc5a29ff60a03(String arg1) {
    return 'Payment: $arg1';
  }

  @override
  String get posa8059b4336f9 => 'Customs duties';

  @override
  String get pos7293acd977ab => 'Import duty';

  @override
  String get posd3eb55d8cbba => 'Direct expense';

  @override
  String get pos81939e0e20a6 => 'Not yet';

  @override
  String get pos6e4dada04531 => 'Unpaid';

  @override
  String get posb986d9ad990c => 'No Direct Purchases yet.';

  @override
  String get pos598513b20333 => 'No Vendor Bills yet';

  @override
  String get posdb8e78b6ec5a => 'No sales activity yet';

  @override
  String get pos899ee8cadfc7 =>
      'No active cash/bank accounts. Set them up in Finance first.';

  @override
  String get pos5c9d5645a0d9 => 'No items in the Purchase Order yet';

  @override
  String get poscb8c5ab29822 => 'No items selected';

  @override
  String get pos46c0b148c7ee => 'No wasted items yet';

  @override
  String get pos15c81191fdf8 => 'No capabilities yet';

  @override
  String get pos7279f5c9e547 => 'No payment data yet';

  @override
  String get posd22960cd0836 => 'No sales data yet';

  @override
  String get pos651b68f6fe3a => 'No product data yet';

  @override
  String get pos6f9c9a1f794d =>
      'No voided transactions are available in this report.';

  @override
  String get pos3308e06280d9 => 'No POS employees have a PIN yet.';

  @override
  String get posa926cc08c2fe =>
      'No active receiving locations. Set up a warehouse before creating a PO.';

  @override
  String get posf6da7e042e93 => 'No tables yet';

  @override
  String get posacd2f4b89b2a =>
      'No active tables in this store. Add tables from Active Orders & Tables.';

  @override
  String get pos5658d501e419 => 'No notifications yet';

  @override
  String get pos73d8486b74a6 => 'No new notifications';

  @override
  String get pos94c914fad3b4 => 'No payments in this period';

  @override
  String get pos8ca874c0e3a4 => 'No goods receipts yet';

  @override
  String get pos57884a94b3d4 => 'No users available for PIN management';

  @override
  String get pos3274d92c93e6 =>
      'No customer ratings recorded for POS transactions yet.';

  @override
  String get pos6f932a5dc6bf => 'No stock movements in this store yet';

  @override
  String get pose9fb26380266 => 'No down payment requests yet.';

  @override
  String get posb0797ccd020a => 'No orders yet';

  @override
  String get posa8504016d97d => 'No active orders at this table';

  @override
  String get pos3fb98935fea6 =>
      'No system printers detected. Check the connection and printer driver, then reload.';

  @override
  String get pos68bd5cb61e21 => 'No products sold in this period';

  @override
  String get posb6d4aa9799f7 => 'No promotions yet';

  @override
  String get pos8a142384fc87 => 'No returns yet';

  @override
  String get pos7433ec2c06fa => 'No supplier returns yet';

  @override
  String get posfe11ad31ef77 => 'No shift history yet';

  @override
  String get posfa31b1ef910c =>
      'No location balances yet. Add stock through receiving, transfers, or Stocktake.';

  @override
  String get posf2005c65e96b => 'No active stores yet';

  @override
  String get posa2fdf4433bf7 => 'No transactions yet';

  @override
  String get pos9c542f99f553 =>
      'No deposit transactions recorded in this period.';

  @override
  String get pos2a03d2d18522 => 'No cashier transactions in this period';

  @override
  String get pos084bf3032b4b => 'No sales trends yet';

  @override
  String get pos92414ac02d75 => 'No warehouses yet';

  @override
  String get poscc03af637140 =>
      'No active warehouses with the Sales Location capability. Enable it in Inventory > Warehouses & Locations.';

  @override
  String get pos2512eb5b68b4 =>
      'No warehouses enabled for purchase receiving yet.';

  @override
  String get posf22109b83333 => 'Unpaid';

  @override
  String get pos18f1630f1efa => 'Uncategorized';

  @override
  String get posb4c54491b1bb => 'Not dispatched';

  @override
  String get pos14cc6d46510e => 'Not rated';

  @override
  String get pos6b18a18f0c5d => 'Not itemized';

  @override
  String get pos7e04d8c095fe => 'Not linked';

  @override
  String get pos1efe06a0e688 => 'Not specified';

  @override
  String get posb90b37ff1647 => 'Not received';

  @override
  String get pos349d5df8e0b6 => 'Not fully paid';

  @override
  String get posddb343c7e461 => 'Don\'t have an account?';

  @override
  String get pos9cb490a9372c => 'Workshop';

  @override
  String get pos6bba8482fe7b => 'Sales format';

  @override
  String get pos8c8cbf07fdcd => 'Sales format *';

  @override
  String posde300b92dea3(String arg1) {
    return 'Switching to $arg1... (Mock)';
  }

  @override
  String get pos014665dae415 => 'Home';

  @override
  String get posdbed99defc36 => 'Weight (kg)';

  @override
  String pos7c7180cb6f69(String arg1) {
    return 'Weight/quantity must match the service quantity in the cart ($arg1).';
  }

  @override
  String get posae7d0610525b => 'By quantity';

  @override
  String get posf2c55794b1c7 => 'By value';

  @override
  String get pos1b4ac3d41520 => 'Next';

  @override
  String get pos0370e213f855 => 'Large';

  @override
  String get pos2f5b87dba6e4 => 'Legacy PO costs';

  @override
  String get posbfe9ecf615b2 => 'Actual costs applied to item values';

  @override
  String pose8182cdba6ee(String arg1) {
    return 'Actual cost $arg1';
  }

  @override
  String get pos08816e7b0295 =>
      'Costs must be whole, non-negative rupiah amounts.';

  @override
  String get pos8f7fb601cfa7 => 'Additional costs';

  @override
  String get pos63b631fe67be =>
      'Additional costs follow the legacy PO workflow.';

  @override
  String pos4ba07f7ac271(String arg1, String arg2, String arg3) {
    return 'Transfer cost Rp$arg1 · $arg2 / $arg3';
  }

  @override
  String get posb607afe9f747 => 'Costs, accounts & dimensions (optional)';

  @override
  String get posbab48ae66a12 => 'Decimals allowed, e.g. 3.5 kg';

  @override
  String get poscd9c695d49e4 => 'Block Completely';

  @override
  String get pos19e493c97a63 =>
      'Bluetooth is unavailable. Enable Bluetooth and allow nearby device access.';

  @override
  String get pose88f4040c3d9 =>
      'May be less than the remaining amount for partial deliveries';

  @override
  String get posa0715d3a79a0 =>
      'You may use a temporary contact person\'s number.';

  @override
  String get posa22c854942d9 => 'The browser cannot read image data';

  @override
  String get posb1fa64be5914 => 'Dispose / reduce stock';

  @override
  String get pos61ee66a29d62 => 'Dispose stock';

  @override
  String get pos8dae890b08ab => 'Create Stocktake';

  @override
  String get pos360cc15b6ba7 => 'Create PIN';

  @override
  String get posca32f5206a2e => 'Create PIN for This Account';

  @override
  String get posd80023a69926 => 'Create Cashier PIN';

  @override
  String get posd111042dd9cb => 'Create a secure PIN';

  @override
  String get pos8614fc0335e0 => 'Create PO';

  @override
  String get pos97fa09336bab => 'Create PO for this stock';

  @override
  String get pos66b53af504dc => 'Create Order';

  @override
  String get posb3e593a0ffd0 => 'Create Order / Pick Up Later';

  @override
  String get pos821ca8d7294b => 'Create Profile & Continue';

  @override
  String get pos1fa1f01587d7 => 'Create Promotion';

  @override
  String get posa73f9c464f90 => 'Create account and continue';

  @override
  String get posc7c1e1b2a335 =>
      'Create and activate a store before opening the kitchen display.';

  @override
  String get pos8205f5d23cde => 'Create an operating location';

  @override
  String get pos368caa939994 =>
      'Create an active sales location to link to a POS store.';

  @override
  String get pos61cd75a720e4 =>
      'Create your first stock location to use outlets and inventory.';

  @override
  String get pos420196e519d7 => 'Create a stocktake';

  @override
  String get pos184157557fa8 => 'Create order / pick up later?';

  @override
  String get posaa415fd24064 =>
      'Place an order with the supplier, then receive the goods when they arrive. Creating a PO does not increase stock.';

  @override
  String get pose26137a4b826 =>
      'Create promotions or vouchers to increase sales and customer loyalty.';

  @override
  String get pos26932da5bd8c => 'Create pairing link';

  @override
  String get pos139ad9e341d7 => 'Create POS store';

  @override
  String get posf1425150ed0d =>
      'Create a POS store and link it to a stock location.';

  @override
  String get pos7ec5aa8a6bf8 =>
      'Create a warehouse/location and ensure it can hold stock.';

  @override
  String get posfd17909d918f =>
      'Create, reset, or unlock cashier employee PINs.';

  @override
  String get posa82a3cd50dd4 => 'Open';

  @override
  String get posb3ddf2f52880 => 'Open Active Orders';

  @override
  String get pos796c94ee5e36 => 'Open Shift';

  @override
  String get pos498ce68c0dd1 => 'Open Cashier Shift';

  @override
  String get posab916481634f => 'Open Shift Now';

  @override
  String get pos56ea24057566 => 'Open Stocktake';

  @override
  String get posf1e83734c2af => 'Open stock and unit rules';

  @override
  String get posafea24434657 => 'Open and monitor shifts';

  @override
  String get pos5444c6986d9e =>
      'Open product details and check the quantity and location hierarchy.';

  @override
  String get posf4921f9ec211 => 'Open cashier';

  @override
  String get pos066fc659b3bc => 'Unlock operator';

  @override
  String get pos16d7a562dfd4 => 'Open operator PIN management';

  @override
  String get pos6cd0bf95632e => 'Open shift';

  @override
  String get posffcd01906370 => 'Open a cashier shift before creating orders.';

  @override
  String get posea8b17847200 =>
      'Open a cashier shift to view this store\'s dashboard.';

  @override
  String get pos4c23101b3098 =>
      'Open a cashier shift to show tables in the active store.';

  @override
  String get pose9f8df76cc9b =>
      'Open a shift at the store you want to manage so tables are kept separate between stores.';

  @override
  String get pos3825c8e27ca2 => 'Open a shift before selecting a table.';

  @override
  String get pos878b88da5fcb =>
      'Open this link on the customer\'s tablet/monitor. It only shows the cart and total, without access to the POS account.';

  @override
  String get posb519abaf52ac => 'Proof of Payment';

  @override
  String get pose588dc62fcf1 =>
      'Proof not submitted. Check your connection and try again.';

  @override
  String get pos07deb6efb37c =>
      'Could not save the draft proof. The return has not been submitted.';

  @override
  String get posc7897ff29a9c =>
      'The local return draft cannot be read. Do not create a replacement; ask an administrator to check.';

  @override
  String get pos0c3d913e5dc7 =>
      'Could not save the proof. The return has not been submitted.';

  @override
  String get posf57d2184db0f =>
      'This proof is only a submission. Mobile does not create payables or a Vendor Bill.';

  @override
  String pos685b57405ff1(String arg1) {
    return 'Proof of loss: $arg1';
  }

  @override
  String get posd271b7b998ee => 'Receipt attachment';

  @override
  String get pos1833807f3c7e => 'Receipt attachment uploaded';

  @override
  String get pos660052e375fe => 'Cancelled payment proof cannot be printed.';

  @override
  String get pos1b7df73ea919 =>
      'Payment record receipts can be reopened from payment history.';

  @override
  String get pos4ff6b8dd30f9 =>
      'The local receipt cannot be read. Do not create a new payment; ask an administrator to check.';

  @override
  String get pos84cc7cca3edd =>
      'Could not save the receipt. The payment has not been submitted.';

  @override
  String get pos7b2f27bd5996 =>
      'Proof submitted. Finance will verify it before creating a Vendor Bill.';

  @override
  String get pos98a45dc13ac8 => 'Branch / Warehouse';

  @override
  String get posc5db540e520b => 'Branch / Outlet';

  @override
  String get pos1d4c0a709c37 => 'Branch / stock location *';

  @override
  String get posc3913ea774d2 => 'Bandung Branch';

  @override
  String get pos9f4b06552ad9 => 'Surabaya Branch';

  @override
  String get pos0cd34cfb1a1c => 'Paying branch';

  @override
  String pos424b98aa8546(String arg1) {
    return 'Paying branch: $arg1';
  }

  @override
  String get pose8081560055d => 'Responsible branch';

  @override
  String get pos5023a9f946b8 => 'Receiving branch *';

  @override
  String pos58c6df885eda(String arg1) {
    return 'Branch: $arg1';
  }

  @override
  String get posd4a5652ee638 => 'Manufacturing Defect';

  @override
  String get pos1d3d9dc32e81 => 'Manufacturing defect';

  @override
  String get posdc0885b7a416 =>
      'Store cache has not been updated; offline shifts may not be ready.';

  @override
  String get pos8c9333b49aed =>
      'Offline scope: cash sales and saving cashier orders. Orders reach tables/kitchen after syncing; electronic payments, shifts, customers, and inventory changes require an internet connection.';

  @override
  String get posa0516ee1776c => 'Mixed';

  @override
  String get pos6c003b6e23a9 => 'Operating capabilities';

  @override
  String get pos40d8fcea97ce => 'How to connect';

  @override
  String get pos08df45881eeb => 'Preparation method *';

  @override
  String get pos3f2275d79afb => 'Search';

  @override
  String get pos5d4d90a9f276 => 'Search GRN, PO, or supplier';

  @override
  String get posa0f36a05b9b3 => 'Find Invoice';

  @override
  String get pos851a9739e744 => 'Search return / invoice no...';

  @override
  String get pos28320e410ffc => 'Search PO or supplier';

  @override
  String get pos19e0d7731f54 => 'Find the PO to receive';

  @override
  String get posbaa59be41455 => 'Search SKU or product name...';

  @override
  String get pos9bdd15bae8f9 => 'Search or scan a product';

  @override
  String get posc9786ac32af9 => 'Search or add a supplier';

  @override
  String get pos509357cda333 => 'Search materials or components';

  @override
  String get posad0a8d45adbe => 'Search items';

  @override
  String get pos0a84e049b97b => 'Search invoices or customers...';

  @override
  String get pos880381e34e30 => 'Search categories';

  @override
  String get pos7d5dad6647f8 => 'Search promotion code or name...';

  @override
  String get pos6128892a6425 => 'Find table';

  @override
  String get pos4c2ea53bb4b3 => 'Search tables...';

  @override
  String get pos16a4a1d8fed2 => 'Search menu';

  @override
  String get posa01a225919b6 => 'Search product name or code';

  @override
  String get posa4c02a6d9615 => 'Search store name or code...';

  @override
  String get pos00d1db3d643f => 'Search name or phone number...';

  @override
  String get pos031c855ae1be => 'Search name or phone...';

  @override
  String get pos8ed9d8f649ac => 'Search name or username…';

  @override
  String get posd1772193eff8 => 'Search name, code, or barcode';

  @override
  String get pos4792ca61c79a => 'Search name, code, SKU, or barcode...';

  @override
  String get pos8c45e1cf3dda => 'Search name, code, or phone';

  @override
  String get pos3f6b1fb10707 => 'Search number / wasted item';

  @override
  String get posa999e7406679 => 'Search transfer number / location';

  @override
  String get pos7bfa890763c1 => 'Search PO number or supplier';

  @override
  String get pos480e34d203d1 => 'Search invoice number / supplier';

  @override
  String get pos01abd969d17f => 'Search stocktake number';

  @override
  String get pos45893b182246 => 'Search order number or customer…';

  @override
  String get pos2c7ddda93ab8 => 'Search return number / supplier';

  @override
  String get posbbf757a632b7 => 'Search order / customer';

  @override
  String get pos0e369e2675c1 => 'Search customers';

  @override
  String get pos6a7ae838b897 => 'Search customer / invoice number';

  @override
  String get pos2b52cbef4d75 => 'Search products...';

  @override
  String get pos8ec5c4f82650 => 'Search reference';

  @override
  String get pos44491bc7acef => 'Search all categories';

  @override
  String get pose53a0b916aed => 'Search store or cashier...';

  @override
  String get pos214f0a2c34f5 => 'Search warehouses';

  @override
  String get posde86a77fb4f6 => 'Record Supplier Response';

  @override
  String get posb0f56a08deaa => 'Record costs';

  @override
  String get pos242aa2e706b3 => 'Record opening cash';

  @override
  String get posccb283cfadfa =>
      'Record opening cash before making transactions';

  @override
  String get pos20ffe2dcf59d => 'Record shipping/actual costs';

  @override
  String get pos3a9e2b952f34 => 'Record payment';

  @override
  String get pos4be7f0b2d102 => 'Record receipt';

  @override
  String get pos9f09aefd0dd4 => 'Notes';

  @override
  String get pos4d40bd22aea8 => 'Notes (optional)';

  @override
  String get pos59ff732632a4 => 'Footer Note 1';

  @override
  String get pos3611e7728d8f => 'Footer Note 2';

  @override
  String get pos207ab68e27c4 => 'Footer Note 3';

  @override
  String get poscab450e481c3 => 'Opening Shift Notes';

  @override
  String get pos750a62716d04 => 'PO notes';

  @override
  String get pos284f0ee8e92f => 'Position Notes';

  @override
  String get posaab3e9bd88a0 => 'Additional Notes';

  @override
  String get pos5018e0878c03 => 'Closing Shift Notes';

  @override
  String get posf6b887f49700 => 'Item notes';

  @override
  String get posa6ea551f47a7 => 'Item notes (optional)';

  @override
  String get pos7bc0abb662e7 =>
      'These notes record the supplier\'s acknowledgement.';

  @override
  String get pos9d266dc2187e => 'Item notes';

  @override
  String get pos429f76d8ac4d => 'Decision notes (required)';

  @override
  String get pos4c0503349b16 => 'Decision notes are required.';

  @override
  String get pos7f28ea292f1e => 'Receiving notes (optional)';

  @override
  String get posf93a11f8dc1f =>
      'Reconciliation notes must contain 5–500 characters, including invoice and cash verification results.';

  @override
  String get pos7e4eb72f29cd => 'Supplier response notes';

  @override
  String get pos179a4b68771a => 'Waste stock record unavailable';

  @override
  String get pos4b4077f266dd => 'Additional notes (optional)';

  @override
  String get posa79789981a31 => 'Installment notes';

  @override
  String get posf1f2ec007def => 'Transaction notes';

  @override
  String get pos9fdeae550e61 => 'Transfer notes';

  @override
  String get pos678064362122 => 'General notes';

  @override
  String get pos61d31d182c5a => 'Notes for Finance';

  @override
  String get pose7a3c1fea4d1 => 'Notes ✓';

  @override
  String get pos850320f14d8a => 'Item notes/reason';

  @override
  String posb0bf84cc5839(String arg1) {
    return 'Notes: $arg1';
  }

  @override
  String pos9715ac503203(String arg1) {
    return 'Notes: $arg1\n';
  }

  @override
  String get pos3de4a8034ba3 => 'Check';

  @override
  String get pos72e4a5528b85 => 'Fast (ESC/POS text)';

  @override
  String get pos6832a5cc9dec =>
      'Fast mode uses ESC/POS text while keeping the template fields. Choose Precise when the logo and PDF layout must match the preview exactly.';

  @override
  String get pose96378dc0a9d => 'Print';

  @override
  String get posbf3948a9c7d1 => 'Print A4 (device dialog)';

  @override
  String get posc9fe212abb29 => 'Print PO (A4)';

  @override
  String get pose75740ca1028 => 'Print A4 PO';

  @override
  String get pos4bd5367ef2a1 => 'Print QR';

  @override
  String get pos6eeefc32fd54 => 'Print QR codes for all tables';

  @override
  String get posdb282005fdde => 'Print Receipt';

  @override
  String get pos5e15d47f8805 => 'Automatic Receipt Printing';

  @override
  String get pos0436e2610a39 => 'Print labels';

  @override
  String get pos81c5b456162a => 'Print barcode labels';

  @override
  String get posb85a4c291fc6 => 'Print directly without a system dialog';

  @override
  String get posb839576681e6 =>
      'Print using the terminal printer selected in Printer Settings. Bluetooth thermal printers use 58/80 mm paper; share the PDF preview for A4 label printing.';

  @override
  String get posa49225d73292 => 'Print receipts automatically';

  @override
  String get pos879f0b1bef59 => 'Channel';

  @override
  String get posec9fa27f5363 => 'Sales Channel';

  @override
  String get pos2732c93ec01e => 'Active Sales Channels';

  @override
  String get pos5378450ff38c => 'Default Sales Channel';

  @override
  String get pos215f81053c80 =>
      'The channel records the transaction source; the price level determines the product price list.';

  @override
  String get pos99f4e83b5182 => 'Delivery channel';

  @override
  String get pos117aaa80c629 => 'Sales channel';

  @override
  String get pos8e3b14cc8ee8 => 'Channel, price level, tax, and promotions';

  @override
  String get pos1ac8ccbface8 =>
      'Channel, fulfillment type, and price level are saved as separate contexts.';

  @override
  String get posd005afbbf88c => 'Channel: Retail';

  @override
  String pos49724ddf398a(String arg1) {
    return 'Channel: $arg1';
  }

  @override
  String get pos48431e7fc690 => 'Check-in';

  @override
  String get posb03be9c4890a => 'Readiness checklist';

  @override
  String get posac0aa5686aed => 'POS readiness checklist';

  @override
  String get pos5eab5c3809a5 => 'Collapse to icons';

  @override
  String get pos30def46f381e => 'Client transaction ID is required';

  @override
  String get pos91fc1531e59b => 'Retry Journal Entry';

  @override
  String get pos4d65e8901484 => 'Try Again';

  @override
  String get pos00108ed7c185 => 'Try connecting to Google';

  @override
  String get pos3a4d28a11e41 => 'Try again';

  @override
  String poseb9c086c8b8f(String arg1) {
    return 'Retry in $arg1 seconds';
  }

  @override
  String get pos883a2e7b41b7 => 'Try another status or reset the filters.';

  @override
  String get pos9b1482c4ef2e => 'Retry';

  @override
  String get pos03569164e0e5 => 'Retry rejected items';

  @override
  String get pos2fafd764d3d0 => 'Suitable for archiving and reprinting';

  @override
  String get pos1798b3ba42ee => 'Completed';

  @override
  String get pos3134925510af =>
      'Sample receipt downloaded. Open the PDF to print.';

  @override
  String get pos4890f7931178 =>
      'Could not prepare the sample receipt. Try without a logo or check your connection.';

  @override
  String get pos3293fef167a9 => 'Could not download the sample receipt';

  @override
  String get pos51308b6e8b02 => 'Example: 081234567890';

  @override
  String get pos898e357d0aec =>
      'Example: 1 box = 12 pcs. The factor is always relative to the base unit.';

  @override
  String get pos7bcecbcde1fe => 'Example: 10';

  @override
  String get pos5c50a1fbf422 => 'Example: Budi Santoso';

  @override
  String get pos22201d029e0f => 'Example: Down payment per supplier pro forma';

  @override
  String get pos1b776cdb429d => 'Example: HEMAT10';

  @override
  String get poscccac117a03d => 'Example: Table 1';

  @override
  String get pose6223f9ee6fb => 'Example: Beverages';

  @override
  String get pos7d0ed2ed463c => 'Example: Mr. Budi\'s order';

  @override
  String get posaafc591a1c5c =>
      'Example: Pantoo Jaya Store or Maju Cooperative';

  @override
  String get pos62144a2a8f91 => 'Example: near the garden';

  @override
  String get pos9bca286a77ca =>
      'Example: incorrect quantity or receiving location';

  @override
  String get pos53a0336ceb4c => 'Example: preferred partner';

  @override
  String get pose7c61a629b5a => 'Example: monthly stocktake or warehouse audit';

  @override
  String get posa7ec0efc73fb => 'Example: no chili, payment reference…';

  @override
  String get posa83ed75221e8 => 'Corporate';

  @override
  String get pos2c25fce5caf7 => 'Ctrl+Delete clear cart · F1 show help';

  @override
  String get posb308c80ddcd3 => 'Customer laundry';

  @override
  String get pos081ae3fdc403 => 'Custom';

  @override
  String get pos484aa1f13bf0 => 'CANCELLED - NOT VALID PAYMENT PROOF';

  @override
  String pose9eafafbbdc8(String arg1, String arg2, String arg3) {
    return 'CANCELLED · $arg1$arg2$arg3';
  }

  @override
  String get pos2473c371f29e => 'PAID';

  @override
  String get pos18a93cadfbd4 => 'DRAFT - NOT APPROVED - NOT AN OFFICIAL ORDER';

  @override
  String get pos52e887b1d178 => 'Sign Up & Start Trial';

  @override
  String pos5ffbf6ce4162(String arg1) {
    return 'Could not load PO list: $arg1';
  }

  @override
  String get pos20848bfc13d4 => 'Sign Up for Mobile POS';

  @override
  String get pos5aa835a174a3 => 'Correction reasons are not available yet';

  @override
  String get pos48db80a52a7a => 'Item list';

  @override
  String get pos1b213e639868 =>
      'The item list was cleared so stock and batches do not use the previous location.';

  @override
  String get pos0bbd7d660e6e => 'Price list applied to products';

  @override
  String get pos0917fb0c311a => 'Could not load the invoice list';

  @override
  String get pos16d4c9851bf6 =>
      'Could not load the cashier list. Check your connection and try again.';

  @override
  String get posa6544b4fc7b4 =>
      'The cashier list has been updated. Select a cashier and enter the PIN again.';

  @override
  String get pos11964f8c8c3c =>
      'The cashier list does not match this session. Sign out and sign in again; unsent offline transactions remain saved.';

  @override
  String get pos6078827d658d => 'Table list is empty';

  @override
  String get posb00b95f31134 => 'Could not load customers. Try again.';

  @override
  String get pos0aad90265c2d => 'Return list not loaded yet';

  @override
  String get pos18b852d98827 => 'Sign up now';

  @override
  String get posa0be338d3aa0 => 'POS store list unavailable';

  @override
  String get pos490ed470f481 => 'In transit';

  @override
  String get pos1a3a18c173e2 => 'Kitchen';

  @override
  String get posc400c1a3475c => 'Store kitchen';

  @override
  String get pos30b35bf928d5 => 'From date';

  @override
  String get posdf17dcc0a2bf => 'Due date basis';

  @override
  String get posd87f47b47e4d => 'Dashboard';

  @override
  String get posc107e17f81a3 => 'Inventory Dashboard';

  @override
  String get pos03f3b45fc439 =>
      'Could not load the dashboard. Check the server service and try again.';

  @override
  String get posf965d3a8b69e =>
      'Offline dashboard is not available yet. Connect once to prepare data on this device.';

  @override
  String get pos43c834aa1dbb =>
      'Online Finance data. Receipts go to the selected cash/bank account, not a new sale or shift cash drawer.';

  @override
  String get pos38e41ab8e289 => 'Vehicle Details';

  @override
  String get pos089bf95c1718 => 'Partner Details';

  @override
  String get pos45f311257113 => 'Customer Details';

  @override
  String get pos5a8f96fbe340 =>
      'Material/product data is incomplete. Load the catalog while online first.';

  @override
  String get posc1d6daf21f74 => 'Data could not be displayed';

  @override
  String get posee6a41d358ee => 'Data reloaded';

  @override
  String get posb7df95de52ac => 'POS dashboard data unavailable';

  @override
  String get posf01e8a6fdf1f =>
      'Inventory data follows the cashier account\'s warehouse permissions.';

  @override
  String get pos60f60e2a769d => 'Cashier data is not ready';

  @override
  String get pos9c9139adbf85 => 'Vehicle details';

  @override
  String get posb0dfaf79e365 => 'Live data from POS transactions';

  @override
  String get pose84f77699217 =>
      'Product master data will sync to the central server. SKU/barcode conflicts will be resolved by the server.';

  @override
  String get pos394acb774655 => 'Tracking data required';

  @override
  String get pos84689d8e8228 => 'Payment data is incomplete';

  @override
  String get posa9ef081bfe11 => 'Settings data not found';

  @override
  String get pos64ff917593dc =>
      'Could not confirm whether orders are empty. Check your connection and reload.';

  @override
  String pos184f17ad7f06(String arg1, String arg2, String arg3, String arg4) {
    return 'Data last saved $arg1/$arg2 $arg3:$arg4';
  }

  @override
  String get pos8c7c7c39b297 => 'Latest data saved on this device';

  @override
  String get posa4bf79e3f75d => 'Data stored securely on the server';

  @override
  String pos644f622b51e8(String arg1) {
    return 'Saved data · $arg1 · Not real-time';
  }

  @override
  String get posa7d5538e2c7d => 'Data not found';

  @override
  String get posd836206df077 => 'Invalid store or table data for QR.';

  @override
  String get posfc74494f5df2 =>
      'Could not verify store and shift data. Check your connection or PIN and try again.';

  @override
  String get pos8399f1eec253 =>
      'Stock, batch, and expiry data are recorded when goods are received.';

  @override
  String get pos48451e69e7b8 => 'Recycle';

  @override
  String get posdf8831116b32 => 'Default Notes';

  @override
  String get pos90f1fcb90983 => 'Transaction defaults';

  @override
  String get poscf2f05740bfc =>
      'For security, use a combination of letters and numbers in your new password.';

  @override
  String get posd080689508ec => 'By continuing, you agree to\n';

  @override
  String get pos51aafce040a2 => 'Requested deposit';

  @override
  String get pos16e8e04bae02 => 'Legacy deposit (no stock)';

  @override
  String get posa076971a19ea => 'Depreciation';

  @override
  String get pos7e9fd192194a => 'Description';

  @override
  String get posee86ab5a4ec8 => 'Cost description';

  @override
  String get pos396817a916ba => 'Purchase description';

  @override
  String get posf7d2ea1a9af1 => 'Product description';

  @override
  String get pos7c9a7c0610c1 => 'Details';

  @override
  String get pos484c446bce76 => 'Details & actions';

  @override
  String get pos7186342ca1c5 => 'Order Details';

  @override
  String get pos40da1155cb2b => 'Return Details';

  @override
  String get pos6c9f7d072fb1 => 'Transaction Details';

  @override
  String get posf2ddf7714819 => 'Detailed reason / chronology';

  @override
  String get posde32af10ad9a => 'Laundry details';

  @override
  String get posdfe99ad316f8 => 'Service details';

  @override
  String get posa715d7fff607 => 'Reservation details';

  @override
  String get posd8a42a009a66 => 'Additional details';

  @override
  String pos849b319bd7c1(String arg1, String arg2) {
    return '$arg1 details #$arg2';
  }

  @override
  String get pos516a8ee6d983 => 'Dev: Custom Endpoint';

  @override
  String get posb751386df8ae =>
      'On the customer\'s tablet or monitor, scan the QR code or open the copied link. No sign-in required.';

  @override
  String get pos2c509d533219 => 'Submitted';

  @override
  String get pos1ed2b478dc44 => 'Cancelled';

  @override
  String get posd3581c34b5fa => 'Cancelled at';

  @override
  String get pos42b86f7c1b0f => 'Paid';

  @override
  String get pos86a0bc70a8c7 => 'Partially paid';

  @override
  String pos39807fd70afd(String arg1, String arg2, String arg3) {
    return 'Paid $arg1 · Allocated $arg2 · Balance $arg3';
  }

  @override
  String get pos5264ac49ed12 => 'Created';

  @override
  String pos74663425a1fa(String arg1) {
    return 'Created ($arg1)';
  }

  @override
  String get pos1216355f2efb => 'Created by';

  @override
  String get posd1778edc3905 => 'Created automatically by the server';

  @override
  String pos8e461e69d307(String arg1) {
    return 'Opened $arg1';
  }

  @override
  String get posc2f087b83545 => 'Posted';

  @override
  String get pose70ef903e04d => 'Recorded by';

  @override
  String get pos710d22161734 =>
      'Recorded by the buyer; not a supplier receipt.';

  @override
  String get pos467c0f809a3c => 'Recorded at';

  @override
  String get poscdce89cf2c57 => 'Washed';

  @override
  String get pos6deabc07d983 => 'Recycled';

  @override
  String get pos8b8e792d8b25 => 'Used to estimate margin';

  @override
  String get pos892f01466fd8 => 'Deleted via Mobile POS';

  @override
  String get pos67c05c254660 =>
      'Calculated automatically from goods receipts (AVCO)';

  @override
  String get posb3b82d71d5ee => 'Packed';

  @override
  String get pos2f26e1050cf3 => 'Dried';

  @override
  String get pos2418f99b37f4 => 'In progress';

  @override
  String get pos9e1e4a8b51eb => 'Dispatched';

  @override
  String get pos5aa9a930457b => 'Sent to supplier';

  @override
  String pos2edf59b130d4(String arg1, String arg2, String arg3, String arg4) {
    return 'Dispatched $arg1 $arg2 · Received $arg3 · Resolved $arg4';
  }

  @override
  String get pos0f258d986494 => 'Confirmed';

  @override
  String get pos75c1a67be0f1 => 'Credited';

  @override
  String get pos54ae749efb6f => 'Served By';

  @override
  String get pos29397b29d260 => 'Dine-in and table management';

  @override
  String get pos6ec1160db69e => 'Shared by the inventory catalog and cashier.';

  @override
  String get pos9d77dbd733a3 => 'Updated';

  @override
  String pos2885c22e700d(String arg1, String arg2, String arg3) {
    return 'Ordered $arg1 at $arg2 · $arg3';
  }

  @override
  String posfc674fc6d98d(String arg1, String arg2, String arg3, String arg4) {
    return 'Ordered $arg1 · Received $arg2 · Remaining $arg3 $arg4';
  }

  @override
  String get posf78fe3459de0 => 'Selected';

  @override
  String get posd8bd5a6d277c => 'Posted';

  @override
  String get pos54dfaef699d6 => 'Processing';

  @override
  String get pos484fed959e5e => 'In preparation at kitchen / station';

  @override
  String get pos6a5efb2d31a3 => 'Served';

  @override
  String get pos0335d447d92f => 'Handed over';

  @override
  String get posb61a3838102a => 'Ironed';

  @override
  String get pos8c5b40927348 => 'Approved';

  @override
  String get pos4d4cb33ec4b2 => 'Prepared';

  @override
  String get pos6cc10ed56760 => 'Discount';

  @override
  String posd20c0326fffe(String arg1) {
    return 'Discount    -$arg1';
  }

  @override
  String get pos8c61328fd3e0 => 'Discounts & Promotions';

  @override
  String get poscd5ad8d1f6c5 => 'Discount (%)';

  @override
  String get posf749315970d3 => 'Manual Discount (%)';

  @override
  String get pos43861a053a64 => 'Best Discount: Manual or Promotion';

  @override
  String get pos39e0acf540f0 => 'Discount and notes (optional)';

  @override
  String get pos35dedebc6b07 => 'Discount must be between 0–100%';

  @override
  String get pos0b805daf00e8 => 'Item discount';

  @override
  String get posd3e06f55da3e => 'Manual discount';

  @override
  String get pos71057d4cb43f => 'Manual discount (%)';

  @override
  String get pos5d822d3c8b42 => 'Manual discount (authorization)';

  @override
  String get posd048abbdcd5a => 'Fixed amount discount';

  @override
  String get pos2e6eaa0f8139 => 'Best discount';

  @override
  String get pos70f216c8f1f8 => 'Invalid purchase discount, tax, or costs';

  @override
  String get pos64f51620d22a => 'Discounts, taxes, and costs';

  @override
  String pos6757573250bc(String arg1) {
    return 'Discount: -$arg1\n';
  }

  @override
  String pos79b4aaf15d61(String arg1) {
    return 'Discount: $arg1';
  }

  @override
  String get posbb04a084fc91 => 'Sorted';

  @override
  String get pos64643bb547ae => 'Accepted';

  @override
  String pos6cbe2ba54793(String arg1) {
    return 'Received    $arg1';
  }

  @override
  String get pos6e35efb55623 => 'Partially received';

  @override
  String get pos1ff41d5332d2 => 'Receive now';

  @override
  String pos4c2897c3151f(String arg1) {
    return 'Receive now ($arg1)';
  }

  @override
  String get pos64ddb219a2b8 => 'Received by supplier';

  @override
  String pos17d47a833e6d(String arg1, String arg2, String arg3) {
    return 'Received $arg1 • Resolved $arg2 • Remaining $arg3';
  }

  @override
  String get pos610ce5495340 => 'Weighed';

  @override
  String get posc4397f065ad2 => 'Rejected';

  @override
  String get pos514476987e3c => 'Rejected by supplier';

  @override
  String pos6565140ed733(String arg1) {
    return 'Rejected: $arg1';
  }

  @override
  String get pos0e97e7214c08 => 'Closed';

  @override
  String get pos9044ca83add5 => 'Closed with discrepancy';

  @override
  String get pos8fc67d6bb35b => 'Sorted by revenue';

  @override
  String get pos3e65f4ff63bc =>
      'The document will be deleted and cannot be recovered.';

  @override
  String get pos30f862ef282a =>
      'The document will be deleted and cannot be recovered. Enter a reason for the audit trail.';

  @override
  String get pos6624aad87bd7 => 'Document updated';

  @override
  String get pos4f085c6005eb =>
      'This document is created by the buyer and is not a receipt issued by the supplier.';

  @override
  String posa8f1911e24f6(String arg1) {
    return 'This document was printed from the system on $arg1.';
  }

  @override
  String get pos537a9dacad2a => 'Inventory purchase order document';

  @override
  String get pose8d8d0eb1f7b =>
      'Official documents require a connection to verify the latest status. Connect and try again; old data is not printed automatically.';

  @override
  String get pos4f1621cbaa3c => 'Digital Wallet';

  @override
  String get pos73021deac09e => 'Draft';

  @override
  String get pos23d33e22acfc => 'Draft';

  @override
  String get pos53c84f0fb661 => 'Draft created';

  @override
  String posf4aa85a645e9(String arg1) {
    return 'Cost draft saved but not applied: $arg1. Check Inventory > Landed Cost.';
  }

  @override
  String get pos75a4016a3b31 => 'Draft saved locally; stock/cash unchanged.';

  @override
  String get pos7e42bb752260 => 'Return draft saved';

  @override
  String pos32665db570e5(String arg1) {
    return 'Draft saved but submission failed: $arg1';
  }

  @override
  String pos8b42dadfb112(String arg1) {
    return 'Draft $arg1 will be deleted and cannot be processed.';
  }

  @override
  String get posb6e666f86c46 => 'Seat guests';

  @override
  String get posb7d4c20c85fb => 'Duration';

  @override
  String get pos1987a1e42ffd => 'Auto-lock duration must be 1–120 minutes.';

  @override
  String get pos2f6682a1a18d => 'Longest duration';

  @override
  String get pos85c05bd848b3 => 'E-Wallet';

  @override
  String get pos5301648dcf6b => 'Edit';

  @override
  String get posffe1b372fccb => 'Edit Table';

  @override
  String get pose0ba251e59ec => 'Edit Outlet';

  @override
  String get pos3112917853d8 => 'Edit Customer';

  @override
  String get pos919aa11d43a8 => 'Edit Product';

  @override
  String get pos17bab1a67eb5 => 'Edit Promotion';

  @override
  String get pos7d401a7f62c7 => 'Edit Warehouse';

  @override
  String get pos84add5b29527 => 'Email';

  @override
  String get poscd9cfacc4a41 => 'Email (optional)';

  @override
  String get pos2f1cfd6ea0cb => 'Activation email sent';

  @override
  String get pos3521ad2ebf75 => 'Could not send activation email';

  @override
  String get pos785e71efc024 => 'Email or WhatsApp number';

  @override
  String get pos983304bee613 => 'Email or username unavailable.';

  @override
  String get pos87c3b4974191 => 'This email is already in use';

  @override
  String pos4502e01c7a52(String arg1) {
    return 'Verification email sent to $arg1. Verify your account first, then sign in to set up your POS.';
  }

  @override
  String get pos8f80d0fdc1ef =>
      'Endpoint saved. Please restart/hot restart the app.';

  @override
  String get pos7f2f6a15cf8d => 'Error';

  @override
  String get posb6c2a17bc667 => 'Estimated cost';

  @override
  String get posa6a149dda389 => 'Estimated cost must be a whole rupiah amount';

  @override
  String get poseca61d4216c1 =>
      'Estimated costs do not increase bills or stock value. Record actual costs during receiving or through landed cost.';

  @override
  String pos917facb520d6(String arg1, String arg2) {
    return 'Estimated margin: Rp $arg1 ($arg2%)';
  }

  @override
  String get posbbb52a27a493 => 'Estimated arrival date';

  @override
  String get pos02f9dede92fd =>
      'Estimated arrival cannot be before the dispatch date';

  @override
  String get posa09085e4ea3c => 'Estimated preparation time';

  @override
  String get posdc027a58c1d8 => 'F1 to view the guide';

  @override
  String get pos74899f949819 => 'F6 cart · F7 discounts · F8 save order';

  @override
  String get pos7bc8b50180e8 => 'F9 saved orders · F10 sales settings';

  @override
  String get pos738a4653220f => 'Invoice';

  @override
  String pos1d39c9ee7007(String arg1) {
    return 'Sales Invoices ($arg1)';
  }

  @override
  String get pos5a617e53a43f => 'Purchase invoice unavailable';

  @override
  String get pos79d8f3b388ed => '60-second fallback';

  @override
  String get pos39c0b929b750 => 'Favorites';

  @override
  String get pos420534b5d146 => 'Favorites saved locally and waiting to sync';

  @override
  String get posdf99a62fb9ce => 'Image file cannot be read';

  @override
  String get posd7decf1aa22b => 'Filter';

  @override
  String get posd3d9ec019f31 => 'Product Filters';

  @override
  String get pos8aa1b56a68b1 => 'Purchase Return Filters';

  @override
  String get pos4d912020c34d => 'Stocktake Filters';

  @override
  String get posd502b23ad42f => 'Waste Stock Filters';

  @override
  String poscd472b2621dc(String arg1) {
    return 'Active filters: $arg1';
  }

  @override
  String get posaeb609066ae3 => 'Filter reasons and dates';

  @override
  String get pos5c5d5d49ebb5 => 'Filter locations and dates';

  @override
  String get pos521018c8bcca => 'Filter customers';

  @override
  String get pos724fd6a109a2 => 'Filter active orders';

  @override
  String get pos261a4017ab53 => 'Filter products';

  @override
  String get pos9e8861c24689 => 'Filter returns';

  @override
  String get posedf803f6fc3b => 'Filter store status';

  @override
  String get posb3fe852fa673 => 'Finance · Supplier bills';

  @override
  String pos73ff67cc0d8e(String arg1, String arg2) {
    return 'Physical batch $arg1 · $arg2';
  }

  @override
  String get posa6184c3c4b18 => 'Physical count without batch';

  @override
  String posb181ba4478da(String arg1, String arg2) {
    return 'Physical $arg1 · Book $arg2';
  }

  @override
  String posb3eb03dd1e68(String arg1, String arg2) {
    return 'Physical $arg1 · allocated $arg2';
  }

  @override
  String get pos869f6e70b024 =>
      'This feature has not been enabled by the tenant\'s Finance team.';

  @override
  String get pos72e206b7fd90 => 'This feature is under development.';

  @override
  String get pos02370c9b6e7c => 'Tables feature disabled';

  @override
  String get posd308a880c1df => 'Operating features';

  @override
  String get posc307c71e021d => 'Other purchasing features';

  @override
  String get pos83fed4c2c818 => 'Receipt Footer';

  @override
  String get pos6b03993ccb88 => 'Invalid email format';

  @override
  String get pos833cfc904919 => 'Photo must be JPG, PNG, or WebP';

  @override
  String get pos637b919a6c4f => 'Invoice photo must be JPG, PNG, or WebP';

  @override
  String get posf46d7da48b61 => 'Pro forma must be JPG, PNG, or WebP';

  @override
  String get pos71e93c87c1b2 => 'Invalid response format';

  @override
  String get posdbb3a5ba3622 => 'Invalid response format from the server';

  @override
  String pos09d0570c7e41(String arg1) {
    return 'Invalid API response format (HTTP $arg1). Try again or contact an administrator.';
  }

  @override
  String get posa5fe855ddf3e => 'Invalid GraphQL response format';

  @override
  String get pos0f5e4f087245 => 'Photo';

  @override
  String get pos78db57fd7866 => 'Invoice photo';

  @override
  String get posf6bcc19ad31c =>
      'The photo enters the Finance queue and does not immediately create a payable.';

  @override
  String get posd65275950187 => 'Product photo';

  @override
  String get pos1b983d2c1189 => 'GRAND TOTAL';

  @override
  String get posf901c08f43dc => 'Combine Manual Discount + Promotion';

  @override
  String get pos224bc6b9119b => 'Failed';

  @override
  String get posb4e2c379fc5d => 'Could not sign out safely. Try again.';

  @override
  String get pos1b40f959803b => 'Could not share the table QR code.';

  @override
  String get pos1b8cd2da2b3d =>
      'Could not create the receipt file. Please try again.';

  @override
  String get pos53291830aa2e => 'Could not create category';

  @override
  String get posb252d4627327 => 'Could not create a table';

  @override
  String get pos92f937bb5794 => 'Could not create product';

  @override
  String get pos094efd6453e9 => 'Could not create promotion';

  @override
  String get posf0f32118ea7b =>
      'Could not open or print the payment proof. Check the printer and try again.';

  @override
  String posb4e271dca4dd(String arg1) {
    return 'Could not open image: $arg1';
  }

  @override
  String get posebe630c6382b => 'Could not open the invoice printing service';

  @override
  String get pos4ff7e02899e3 => 'Could not open shift';

  @override
  String get pos803763bbee6d =>
      'Could not verify the cash in/out result. Reload before trying again.';

  @override
  String get posec9fe1b66848 =>
      'Could not verify the shift closing result. Reload before trying again.';

  @override
  String get posab8c52527c01 => 'Could not move the order. Try again.';

  @override
  String get pos7c77c31da98c => 'Could not update outlet';

  @override
  String get posd30eedfe6de6 => 'Could not update customer';

  @override
  String get posdf4880ac2cf1 =>
      'Could not process the document. Reload to check its status.';

  @override
  String pos1b53e9ce9719(String arg1) {
    return 'Could not load unit conversions: $arg1';
  }

  @override
  String get pos3cbe80b3fcca => 'Could not load transaction history';

  @override
  String get pos3c846dece8ad =>
      'Could not load transaction history. Pull to retry.';

  @override
  String get posaf44df03a0aa => 'Could not load all tables for printing.';

  @override
  String get pos511e4132f12f => 'Could not load active cashier shifts';

  @override
  String get pos1801846f09c3 => 'Could not load more transactions.';

  @override
  String get pos16483d7d4df7 => 'Could not add outlet';

  @override
  String get posc3f3bd12f9f3 => 'Could not add customer';

  @override
  String get pos4e6a0ac973aa => 'Could not submit return';

  @override
  String get posee01c4493ae8 => 'Could not delete outlet';

  @override
  String get pose3649adbbe7e => 'Could not delete customer';

  @override
  String get pos495296b777e2 => 'Could not delete promotion';

  @override
  String get pos02af68ce1478 => 'Could not delete return';

  @override
  String get pos1a21dc8ed086 => 'Could not change promotion status';

  @override
  String get pose0a9a444a6ff => 'Could not update table';

  @override
  String get posc172b66da4d1 => 'Could not update product';

  @override
  String get pos46e82b0ae0c8 => 'Could not update promotion';

  @override
  String get posee6c48daa9fd => 'Could not close shift';

  @override
  String get pos976fbff96b8d => 'Could not approve return';

  @override
  String posc2b7886b6824(String arg1) {
    return 'Could not prepare PO: $arg1';
  }

  @override
  String get pos5df42ee84e41 => 'Could not prepare QR codes for all tables.';

  @override
  String get pos2ee9ffe5a92d => 'Could not prepare table QR printing.';

  @override
  String get posc954d5ca3c3a => 'Could not prepare labels.';

  @override
  String get posddb9aa8fd356 => 'Could not save or retrieve local data';

  @override
  String get pos4c687db5daf2 => 'Could not save data';

  @override
  String get posd4aa54d3272d => 'Could not save settings';

  @override
  String get pos0fef5416efb2 => 'Could not save petty cash';

  @override
  String get pos23e2e47741e6 =>
      'The CAPTCHA image could not be displayed. Please try logging in again.';

  @override
  String get pos0dfd02112e86 => 'Change';

  @override
  String get pos58d72143f2f5 => 'Change PO';

  @override
  String get posc032d55c32f0 => 'Change image';

  @override
  String get posf6b4e4763c6f => 'Change location';

  @override
  String get pos37433a332509 => 'Change source location?';

  @override
  String get posd7ec1542ac28 => 'Building';

  @override
  String get poseea149a1c095 => 'Building (optional)';

  @override
  String pos7fac25ce1b1f(String arg1) {
    return 'Building $arg1';
  }

  @override
  String get pos62f72c81b717 => 'Building, room & rack (optional)';

  @override
  String get pos236ae339131d =>
      'Building, room, and rack are optional, but help track balances more precisely.';

  @override
  String pos786a448f1a32(String arg1) {
    return 'Building: $arg1';
  }

  @override
  String get pos5920cc131a58 => 'Dark';

  @override
  String get pos0bdb72ba702c => 'Regenerate SKU and barcode';

  @override
  String get pos608b62493d5c => 'Swipe card';

  @override
  String get posb4b96ac14e22 => 'Swipe the card right for the next stage';

  @override
  String get posf13036b0f9c9 =>
      'Scroll the table sideways to fill in the other columns.';

  @override
  String get pos8a813f3e08f2 => 'Bank Draft';

  @override
  String get pos1b155396b4ca =>
      'Could not connect to Google. Please try again.';

  @override
  String get posb10adea98b92 =>
      'Google did not provide account verification. Please try again.';

  @override
  String get pose0a9270ba48f => 'Google is not available on this server yet.';

  @override
  String get pos2f1334888329 =>
      'Google is unavailable. You can still sign in or sign up with email.';

  @override
  String get posece89223a27e => 'Sales chart';

  @override
  String get pos650fe991ac42 => 'Grand total';

  @override
  String get pos38849fb0615b => 'GraphQL Endpoint';

  @override
  String get posd969fdbaeddf => 'Branch warehouse';

  @override
  String get pos8cc222a3287a => 'Central warehouse';

  @override
  String get posccc625ad01b5 => 'Store warehouse';

  @override
  String get posface83ee3014 => 'Guest';

  @override
  String get pos77a9bf43ee61 => 'Use';

  @override
  String get pos1324bb13a47e =>
      'Use 4–6 digits that the operator can remember but others cannot easily guess.';

  @override
  String get posd3ef9894d6f0 =>
      'Use History to reprint, resume invoices, or process returns.';

  @override
  String get pos0c4c95dc7004 => 'Use letters, numbers, periods, _ or -';

  @override
  String get pos2578dc120c2a => 'Use quantity';

  @override
  String get pos68c6220bf962 => 'Use code';

  @override
  String get pos06b348aec71c => 'Use stock composition / recipe (BOM)';

  @override
  String get pos1344c75514e1 => 'Use an active number starting with 0 or 62';

  @override
  String get pos24457d2732a0 => 'Use a valid phone number (8–15 digits)';

  @override
  String get pos6da08cf9e00e => 'Use walk-in customer';

  @override
  String get pos83eaa0de7240 =>
      'Use search, categories, favorites, or the barcode scanner.';

  @override
  String get pos77b44b71db37 =>
      'Use purchase receiving for incoming goods, or opening stock/corrections for opening balances.';

  @override
  String get pos5b22a1493baf =>
      'Use receiving, returns, or scrap with explicit serial numbers. Serial quantity corrections are not supported in stocktake yet.';

  @override
  String get pos5f9f4a96fb84 =>
      'Use receiving/returns/scrap with serial numbers.';

  @override
  String get pos18060473474f =>
      'Use stock products, services, or bundles according to how the item is sold.';

  @override
  String posca170b43672a(String arg1, String arg2) {
    return 'Composition cost Rp $arg1$arg2';
  }

  @override
  String get pos1d846b91a00b => 'Out of stock';

  @override
  String get pos59f7d7f90bfb => 'Consumables';

  @override
  String get pos648e401ed6fa => 'Next page';

  @override
  String get posb0fd7e079f01 => 'Could not open the legal page.';

  @override
  String get pos74d76fb1e7d3 => 'Previous page';

  @override
  String pos4d0803eab0a2(String arg1) {
    return 'Page $arg1';
  }

  @override
  String pos61f7b0c13f15(String arg1, String arg2) {
    return 'Page $arg1 / $arg2';
  }

  @override
  String posea3f79a3c91b(String arg1, String arg2) {
    return 'Page $arg1 of $arg2';
  }

  @override
  String pos6a42159c5abb(String arg1, String arg2) {
    return 'Page $arg1 · $arg2 categories';
  }

  @override
  String pos189db84b3f7d(String arg1, String arg2) {
    return 'Page $arg1 · $arg2 components';
  }

  @override
  String posad518ced7c3d(String arg1, String arg2) {
    return 'Page $arg1 · $arg2 requests';
  }

  @override
  String posd628bb3772f8(String arg1, String arg2) {
    return 'Page $arg1 · $arg2 orders';
  }

  @override
  String posd56e0c97a9f6(String arg1, String arg2) {
    return 'Page $arg1 · $arg2 options';
  }

  @override
  String posddeedb7fc620(String arg1, String arg2) {
    return 'Page $arg1 · $arg2 products';
  }

  @override
  String pos49f816b08de3(String arg1) {
    return 'Hello, $arg1 👋';
  }

  @override
  String get pos6c94476426e3 => 'Handling';

  @override
  String get pose0174d444b53 => 'Manual Discount Only';

  @override
  String get posdd40e443b7fa => 'Promotion Only';

  @override
  String get pos5bac0e78561a => 'View only';

  @override
  String get pos172bc678f03c =>
      'Only authorized users with a PIN can open a cashier session.';

  @override
  String get pos4b7b05435e97 =>
      'Only for separately paid shipping/costs. If shipping is on the same supplier invoice as the goods, record it through a Vendor Bill in Finance web for one fully billed GRN; do not record it here to avoid duplicate payables.';

  @override
  String get pose8f25ae79a1c =>
      'Only active warehouses with the Sales Location capability';

  @override
  String get pos9d053c98fde4 => 'Delete';

  @override
  String get posd350eb5f85c1 => 'Delete Table';

  @override
  String get pos5711e2078686 => 'Delete Promotion';

  @override
  String get pose817b0f4863b => 'Remove item';

  @override
  String get pos8dc1f033132c => 'Remove cost';

  @override
  String get pos389385909a93 => 'Delete return draft?';

  @override
  String get pose6eff93e6a27 => 'Remove photo';

  @override
  String get posde0e62337399 => 'Remove schedule';

  @override
  String get pose78112cde662 => 'Remove conversion';

  @override
  String get pos04ec30ffeb21 => 'Remove method';

  @override
  String get posf73f077fe3c3 => 'Delete outlet?';

  @override
  String get pos7878b0d8997e => 'Delete customer?';

  @override
  String get posb51ee6066ff5 => 'Delete purchase return?';

  @override
  String get posd42e339038ff => 'Clear date';

  @override
  String get poscbed1954f6c3 => 'Delete warehouse?';

  @override
  String posb45b8e526f3f(String arg1) {
    return 'Remove $arg1 from favorites';
  }

  @override
  String get pos059e7656ec55 => 'Price';

  @override
  String get pos728a37639a44 => 'Corporate Price';

  @override
  String get pos1ba6727611e6 => 'Distributor Price';

  @override
  String get pos61d717e6a361 => 'Retail Price';

  @override
  String get posf0d242effb62 => 'Wholesale Price';

  @override
  String get pos7d9d78a74ccb => 'Selling Price';

  @override
  String get pos1cba3d99c4b2 => 'Member Price';

  @override
  String get pos08d741fe3e42 => 'Reseller Price';

  @override
  String get pos1e1a56a7fdd2 => 'VIP Price';

  @override
  String get pos67af8b49dbf7 => 'Purchase price';

  @override
  String get pos47fd3ba771f7 => 'Purchase price / cost';

  @override
  String get pos0f54f8223fa1 => 'Purchase price per unit';

  @override
  String get pos6c49a243b754 => 'Selling price';

  @override
  String get pose4d6b23f3352 => 'Selling price *';

  @override
  String get posfcc71c6d0fa8 => 'Cost price';

  @override
  String posba0f270a2974(String arg1) {
    return 'Price $arg1';
  }

  @override
  String get posd300b7bcaae8 => 'Today';

  @override
  String get pos2c6ad1441fa8 => 'Today';

  @override
  String get pos46d1bb285515 =>
      'Result not confirmed. Check the transfer status before retrying.';

  @override
  String get pos111ba08784da =>
      'Refund result not confirmed. Do not pay out again. Check the return status when connected.';

  @override
  String get posf32d12e478fb => 'Reconciliation result / proof number';

  @override
  String get pos1e17ce7f8720 => 'Receipt Header';

  @override
  String get pos71efaa642140 => 'Lost';

  @override
  String get posf96204859cd2 => 'Lost / permanent shortage';

  @override
  String get pos9b43a9323e44 => 'Lost/short';

  @override
  String get posc35fb6745fcf => 'Count with conversions';

  @override
  String get pos42045bba2963 => 'Count by batch';

  @override
  String get posf0b4d6c6e6c1 => 'Count stock';

  @override
  String get pos4a88241970e3 => 'Count stock at this location';

  @override
  String get pos2c1369113bcd => 'Count/correct by batch';

  @override
  String get posac2ed926abe5 =>
      'Contact an administrator for permission to view store stock.';

  @override
  String get posbe42365b3845 =>
      'Contact an administrator for permission to manage tables.';

  @override
  String get posc93991607418 => 'Connect Customer Display';

  @override
  String get pos6988b7016ba0 => 'Connect customer display';

  @override
  String get pos6883cf015f7e => 'Link stock location';

  @override
  String get pos1da990c78361 =>
      'Link the active store to a sales location first.';

  @override
  String get pos9537523da00d => 'Payable cancelled';

  @override
  String get posf67b1a19f6eb => 'PO ID unavailable';

  @override
  String get pos8bb0f77f5f25 => 'Payment ID';

  @override
  String get pos24e0b20d63a9 => 'Order ID unavailable';

  @override
  String get posecc15f135718 => 'Invalid order ID';

  @override
  String get pos6cef3759bcbb => 'Invalid order ID. Reload the order.';

  @override
  String get pos00e61a9042b4 => 'Bill ID unavailable';

  @override
  String get posfe1a6c8519c8 => 'INVOICE';

  @override
  String get pos89ae2350ce7b => 'Organization or user identity unavailable';

  @override
  String get pos8f15bdaa0369 =>
      'Organization, store, or offline order identity unavailable';

  @override
  String get posdd1efa7c5f1f =>
      'Original cashier identity unavailable. This transaction needs administrator review.';

  @override
  String get pos740dea0268ce => 'Customer vehicle identification';

  @override
  String pos67bae1d899bf(String arg1) {
    return 'Could not load buyer identity: $arg1';
  }

  @override
  String get pos1bbd060dbfe8 => 'POS store identity';

  @override
  String get pos0b843309058d =>
      'Batch identity/quantity does not match the remaining transfer.';

  @override
  String get posa2853109d1eb => 'Follow organization policy';

  @override
  String get posb5e55c9dbb49 =>
      'Follow the highlights to add items, set the order context, and check the total.';

  @override
  String get pos4b631f698425 => 'Info';

  @override
  String get posaa72b721e803 => 'Stocktake information & location';

  @override
  String get pos39ed5e099637 => 'Product Information';

  @override
  String get pos04ebcc29713d => 'Promotion Information';

  @override
  String get pos6a6754295abb =>
      'This information guides Finance. Creating a PO does not create a payable or record a payment.';

  @override
  String get pos2db5d5d597a2 => 'Purchase information';

  @override
  String get pos794d3faa5c0c => 'Receiving information';

  @override
  String get pos92efbb82664b => 'Product information';

  @override
  String get pos8d749d079e06 => 'Transfer information';

  @override
  String get pos3a187ec13ed4 => 'Enter physical count';

  @override
  String get pos7f53b7abb18f => 'Input unit / packaging';

  @override
  String get posf53c87ea7127 => 'Inspection';

  @override
  String get posc2804192832a => 'Intangible';

  @override
  String get pos844739bd2099 => 'Internal cashier';

  @override
  String get pos66c06c11d179 => 'Internet';

  @override
  String get pos77b5136d4e8b => 'Inventory';

  @override
  String get posf9f38818c406 => 'Invoice';

  @override
  String get pos24b6f23a456c => 'Original Invoice';

  @override
  String get pose61508685db4 => 'Unpaid Invoices';

  @override
  String get posdf484f04f890 => 'Invoice cancelled';

  @override
  String get pos4900d09d9809 => 'Could not create invoice';

  @override
  String get pos95347c107273 =>
      'Offline invoice saved. It cannot be paid yet; check Queue & Sync.';

  @override
  String pos498daa89ff78(String arg1) {
    return 'Server invoice: $arg1. Check transaction values, prices, and physical cash before marking the review complete. Do not resend as a new transaction.';
  }

  @override
  String get posb65d7cb22df8 =>
      'Invoice issued. Settle it through Receivables in Finance.';

  @override
  String get posab8d9d4d63c5 => 'Supplier invoice';

  @override
  String get posc5670e9d9652 => 'Invoice saved · awaiting payment';

  @override
  String get pos0e45fc42efe8 => 'Invoice mismatch';

  @override
  String get poscc106607c66b => 'Invoice not found';

  @override
  String get pos8b0377d34af1 =>
      'Invoices verified by Finance will appear here.';

  @override
  String pos3818e7b1db75(String arg1) {
    return 'Invoice $arg1';
  }

  @override
  String pos4def2db5b18e(String arg1) {
    return 'Invoice $arg1 paid';
  }

  @override
  String pos3a368a74f5da(String arg1) {
    return 'Invoice $arg1. Restore the submitted entries before creating another return. This does not request or pay a refund.';
  }

  @override
  String posee94ad7e244c(String arg1) {
    return 'Invoice: $arg1';
  }

  @override
  String get pos960c2dafc91f => 'Restock Display Rack';

  @override
  String get pos18372bff924d =>
      'Enter a whole rupiah amount up to the outstanding balance, receiving account, and proof number.';

  @override
  String get pos5b074a10c758 => 'Enter shipping address';

  @override
  String get pos4fd509646f1e =>
      'Enter a reason of at least 10 characters and tick the acknowledgement.';

  @override
  String pos42d67456c6c0(String arg1) {
    return 'Enter a reason for $arg1 discrepancy, at least 3 characters';
  }

  @override
  String pos9fec2fcbc391(String arg1) {
    return 'Enter a reason for $arg1 discrepancy, at least 3 characters.';
  }

  @override
  String get pos068dd112192d => 'Enter a number from 1–100';

  @override
  String get pos7bf0a2ca4ee6 => 'Enter zero or a positive number';

  @override
  String get posa4d4a5b8ded1 =>
      'Enter only goods that actually arrived. Remaining and pending discrepancies are not automatically received.';

  @override
  String get posaec5933834f8 => 'Enter the detailed disposal reason';

  @override
  String get pose552d7de417f =>
      'Enter warehouse details. Name and address are required to identify the location.';

  @override
  String posd06dba4cee38(String arg1) {
    return 'Enter a quantity from 0 to $arg1';
  }

  @override
  String get pos3dab9217cedf => 'Enter a valid physical quantity';

  @override
  String get pos3a193722be00 =>
      'Enter a non-negative package quantity and valid conversion factor.';

  @override
  String pos87d6dcc5b9dd(String arg1) {
    return 'Enter the quantity per package. The system calculates the total in $arg1.';
  }

  @override
  String get pos46a82e97da42 =>
      'Enter the quantity that actually arrived. The remainder stays in transit.';

  @override
  String get pos86399e5bb71d => 'Enter at least one received quantity';

  @override
  String get pos677c7a68dc45 => 'Enter at least one quantity to process.';

  @override
  String get pos4b026df5b239 => 'Enter at least one unit.';

  @override
  String get pos43dca23d4112 =>
      'Enter the store name and code shown on transactions and receipts.';

  @override
  String get pos681bcce6a36e => 'Enter an option name first.';

  @override
  String get posb8492d02d692 =>
      'Enter a short product name that cashiers can recognize.';

  @override
  String get posb784b2892be6 =>
      'Enter the store name and details shown on transactions and receipts.';

  @override
  String get posfddd62cd0dea =>
      'Enter name, category, unit, price, SKU/barcode, and a photo if needed.';

  @override
  String get pos1aaeb76923cd =>
      'Enter a service item or complaint, at least one is required.';

  @override
  String get posf62435f24f32 => 'Restock display rack';

  @override
  String get pos694ca219260b => 'Enter base unit';

  @override
  String get posed6b2fa03012 => 'Fill in all remaining quantity for this line';

  @override
  String get pos12a293d406a4 =>
      'Enter zero or a positive number for every physical quantity.';

  @override
  String get posb0dc8b63cbec => 'Enter opening stock';

  @override
  String get posd8a2ff97ecdc =>
      'Enter opening stock after creating the product.';

  @override
  String get posf571768b6250 =>
      'Enter valid physical and posting dates (YYYY-MM-DD).';

  @override
  String get posecdda59aea5e => 'Item';

  @override
  String get pos021cd2ea7514 => 'Purchase Items';

  @override
  String get posb94f9ded282d => 'Top Product Items';

  @override
  String get pos5f3e283632e3 =>
      'Items can be handed over directly or sent to the kitchen/bar.';

  @override
  String get posea0309ed55f6 =>
      'Kitchen item has no valid ID. Reload the order.';

  @override
  String get pos8fea91694ec2 => 'Service items';

  @override
  String get pos9abf395c316a => 'Permission';

  @override
  String get pos0249c76f6e84 =>
      'Bluetooth permission permanently denied. Enable Nearby devices in App Settings.';

  @override
  String get pos29131337e7c9 =>
      'Scrap approval permission unavailable. You can only reject; an authorized supervisor must approve.';

  @override
  String get poscfadf68bfea9 => 'Allow Cashier to Edit Prices';

  @override
  String get pos12d2cd6e66b7 => 'Allow Sales Without an Active Shift';

  @override
  String get posc873500afc78 =>
      'Allow Nearby devices (Android 12+) or Location (Android 10/11) to find printers.';

  @override
  String get pose5ca412acd29 => 'Allow with Authorization';

  @override
  String get pos6d9747726c3e => 'JPG, PNG, or WebP • up to 5 MB';

  @override
  String get pos630e28585a4f => 'Payment Installment Schedule';

  @override
  String get pos8bb5b1a09462 =>
      'A service schedule is required for reservations.';

  @override
  String get pos8d8ce1f777c6 => 'Customer schedule';

  @override
  String get pos64744b573d98 => 'Reservation schedule updated';

  @override
  String get pos9059226e133b =>
      'The reservation schedule is checked before payment. If payment is cancelled, the reservation remains in Active Orders to resume later.';

  @override
  String get pos85bf1ddd2dd3 => 'Could not process the reservation schedule';

  @override
  String get pos88b9ef6a0784 =>
      'Installment schedule unavailable. Refresh the PO or contact an administrator before recording payment.';

  @override
  String posbfa60931a0a5(String arg1) {
    return 'Schedule: $arg1';
  }

  @override
  String get pos8257c2080610 => 'Reschedule';

  @override
  String get pos2f4d174beca0 => 'Reschedule reservation';

  @override
  String get pos8402e5e930c8 => 'Order Time';

  @override
  String pos4a5790de1739(String arg1) {
    return 'Do not repeat the refund until the return status is confirmed. $arg1';
  }

  @override
  String get poscef3e9d96af0 => 'Invalid credit term';

  @override
  String get posaee3ad0696eb =>
      'Device network available. The server is checked during transactions.';

  @override
  String get pos873385d700da => 'Services';

  @override
  String get pos8a49b0cab4ef => 'Services / Appointments';

  @override
  String get pos165b11818801 => 'Due date';

  @override
  String get pos6b5c41c5f9d4 => 'Payment term (days)';

  @override
  String get posa2461e28f412 =>
      'The due date follows the receipt date. Receiving records stock and GRNI only; payables are created after Finance posts the invoice.';

  @override
  String get pos2305cc99bfbb => 'Due soon';

  @override
  String pos0c8620dab460(String arg1) {
    return 'Due: $arg1';
  }

  @override
  String get posc6b8aa8f3866 =>
      'Explain why the remaining goods will not be received';

  @override
  String get posfabb2b5c779a => 'Type';

  @override
  String get pos2e99133d9825 => 'Value Type';

  @override
  String get posa54013c11f44 => 'Payment Type';

  @override
  String get pos653eb5e1517f => 'Order Type';

  @override
  String get pos68d1bcb419e2 => 'Default Order Type';

  @override
  String get poscbcb5c510e6b => 'Cost type';

  @override
  String get posb33a27088b2c => 'Discount type';

  @override
  String get pos704467719529 => 'Item discount type';

  @override
  String pos60e3a1766a6e(String arg1) {
    return 'Unknown queued operation type: $arg1';
  }

  @override
  String get posb1e87cb3d8dc => 'Order type: Takeaway';

  @override
  String pos351aef710752(String arg1) {
    return 'Order type: $arg1';
  }

  @override
  String get posb31bb29fd469 => 'Discrepancy type';

  @override
  String get posbb1ab312f123 =>
      'If paid separately, record it now to include the cost in item values. PO estimates are not charged automatically.';

  @override
  String get pos1a3535f3f905 =>
      'If the physical invoice has arrived, submit its photo for Finance verification.';

  @override
  String get pos338c62110b22 =>
      'If blank, the server generates an internal EAN-13 barcode.';

  @override
  String get posd33f413944c9 =>
      'If the link does not open, check that both devices are on the same network and the router\'s device isolation is disabled.';

  @override
  String get posc0f585c44ba8 => 'Jl. Asia Afrika No. 10, Bandung';

  @override
  String get pos2668f5896214 => 'Jl. Sudirman No. 1, Jakarta Pusat';

  @override
  String get posa946b3e9bada => 'Jl. Tunjungan No. 5, Surabaya';

  @override
  String get posaa99b2216b01 => 'Title (Line 1)';

  @override
  String get posafb0a31422e0 => 'Main Title';

  @override
  String get posdcb86663713e => 'A title is required';

  @override
  String get pos755c97873b6a => 'Quantity';

  @override
  String get pose7150b7c11bb => 'Amount (Rp)';

  @override
  String pos8109832b1b60(String arg1) {
    return 'Quantity ($arg1)';
  }

  @override
  String get pos443be1dee7c9 =>
      'Open PO quantities already meet the target stock.';

  @override
  String get pos9d3ddbcdda58 => 'Item quantity must be positive.';

  @override
  String get pos947f16e391d6 => 'Quantity successfully recycled';

  @override
  String get pos8aeb9aa96315 => 'Quantity to process';

  @override
  String get pos51b76460b766 =>
      'Received quantity updated. Check the batch and location before saving.';

  @override
  String get pos807ac846d704 => 'Invalid received quantity';

  @override
  String get pos032f507eb0f4 => 'Physical quantity';

  @override
  String get pos537a99d1024c => 'Physical batch quantity cannot be negative';

  @override
  String posfd2ad4755705(String arg1, String arg2) {
    return 'Quantity must be 0 to $arg1 $arg2.';
  }

  @override
  String get posb0fa83b331ee =>
      'Quantity must be non-negative and cannot exceed the available remainder.';

  @override
  String posfb4a0df20901(String arg1, String arg2) {
    return 'Recycled quantity for $arg1 must be 0–$arg2';
  }

  @override
  String pos2a8779efd3b6(String arg1) {
    return 'Lost quantity for $arg1 exceeds the batch balance';
  }

  @override
  String get pos2493b57b023e => 'Item count';

  @override
  String get posd9512d28962d => 'Label quantity (1–50)';

  @override
  String get posbafa7741b996 => 'Label quantity must be 1–50.';

  @override
  String get pos990f037d4332 => 'Thermal label quantity must be 1–8.';

  @override
  String posda44a8c5e2db(String arg1) {
    return 'Amount exceeds the outstanding payable ($arg1).';
  }

  @override
  String pos0933c14b6cfc(String arg1) {
    return 'Amount exceeds the remaining installment ($arg1).';
  }

  @override
  String get posca46c6d39fc4 =>
      'The number of unique serial numbers must match the item quantity.';

  @override
  String get pos65f277f99e7e => 'Payment amount *';

  @override
  String get pose434144b33a9 => 'Receipt amount (Rp)';

  @override
  String get pose7dda6f78955 => 'Quantity per unit / package';

  @override
  String pos981fefc1e33c(String arg1) {
    return 'Return quantity ($arg1)';
  }

  @override
  String get posf9ee5fc6a4d3 => 'Location balance quantity';

  @override
  String get pos01ceffc734ca => 'Unit quantity must be non-negative.';

  @override
  String get poscab1f74c7c7e =>
      'The billed quantity follows the service quantity in the cart. Tap the cart quantity to change weight/quantity.';

  @override
  String get pos0df65f44728b => 'Guest count';

  @override
  String get posd629ec82f452 => 'Number of installments (2–12)';

  @override
  String get pos50ec82b77842 =>
      'Suggested quantities consider stock and open POs. Review demand, prices, and supplier before saving the PO.';

  @override
  String posfed87456b577(String arg1) {
    return 'Quantity $arg1';
  }

  @override
  String pos5b84c2d40d4c(String arg1) {
    return 'Quantity for $arg1 updated.';
  }

  @override
  String pos7ee454b3f2c2(String arg1, String arg2, String arg3) {
    return 'Quantity for $arg1 must be greater than 0 and at most $arg2 $arg3';
  }

  @override
  String pos0502434efde2(String arg1, String arg2, String arg3) {
    return 'Maximum quantity for $arg1 is $arg2 $arg3';
  }

  @override
  String posad42a01ae2c6(String arg1, String arg2, String arg3) {
    return 'Quantity for $arg1 exceeds location stock ($arg2 $arg3)';
  }

  @override
  String posd73d69d726dc(String arg1) {
    return 'Journal entry incomplete: $arg1';
  }

  @override
  String get pos56f27547fcc3 =>
      'Journal entry not confirmed. Use Retry Journal Entry.';

  @override
  String get pos8adf9b478501 =>
      'Could not process the journal entry. Reload to check its status.';

  @override
  String pos4c593ad5f42d(String arg1) {
    return 'Journal entry failed: $arg1';
  }

  @override
  String posa1928b385d2d(String arg1) {
    return 'Reversal journal entry incomplete: $arg1';
  }

  @override
  String get posd932dbb48b4d => 'Reversal journal entry updated';

  @override
  String get pos635ac7ca192e => 'Receiving journal entry updated';

  @override
  String get pos86f313ec201e => 'Scrap journal entry updated';

  @override
  String pose627ba45da07(String arg1, String arg2) {
    return 'Journal entry: $arg1$arg2';
  }

  @override
  String get pos1c18b07a4c12 => 'OTHER CATEGORIES';

  @override
  String get pos6417dc96dd89 => 'Expired';

  @override
  String get pos3fd661d8c272 => 'Prospective Partner';

  @override
  String get pos9519ed0538ae => 'Capacity';

  @override
  String get pos5337214524ee => 'Seating Capacity';

  @override
  String pos50275ce55359(String arg1) {
    return 'Capacity: $arg1 People';
  }

  @override
  String posf4f1e83621da(String arg1, String arg2) {
    return 'Capacity: $arg1 seats$arg2';
  }

  @override
  String get posdeaa3060dc73 => 'Quarantine';

  @override
  String pos9b789015b765(String arg1) {
    return 'Quarantine: $arg1';
  }

  @override
  String get pos6760171d6a3c => 'Debit Card';

  @override
  String get pos2800248d00b9 => 'Credit Card';

  @override
  String get posbb1ee7385e63 => 'Employee';

  @override
  String get pos59cd57f7989b => 'Employee not found';

  @override
  String get pos1749b0cd9a9a => 'Payment cash / bank account';

  @override
  String get pos4c2dbc3f372c => 'Actual Cash';

  @override
  String get pose9518d0bc9a4 => 'Opening Cash';

  @override
  String get posa8fe0dd3179a => 'Opening Cash (Rp)';

  @override
  String get pos8b3c8b8f3e44 => 'Expected Cash';

  @override
  String get pos7796b33a3260 => 'Actual Physical Cash (At Closing)';

  @override
  String get pos3922fba5c102 => 'Cashier Cash';

  @override
  String get pos6a1707dcf187 => 'Cash Out';

  @override
  String get pos2f0711c7a173 => 'Cash Out (Withdrawal)';

  @override
  String get posa44379c56411 => 'Cash In';

  @override
  String get posf42c4fa8721b => 'Cash In (Add Funds)';

  @override
  String get pos577ada5e540c => 'Opening cash';

  @override
  String get pos493f3c681020 => 'Cash in / out';

  @override
  String get posaab29c0a1124 => 'Expected cash';

  @override
  String pos3e08d3d71a70(String arg1) {
    return 'Cash $arg1 recorded!';
  }

  @override
  String get posfb5ff76f1668 => 'Cashier';

  @override
  String get posab572ef96179 => 'Cashier & Security';

  @override
  String posf9195de99c01(String arg1) {
    return 'Cashier ($arg1)';
  }

  @override
  String get pos0d960b0b7ec9 => 'Pantoo Cashier';

  @override
  String get pos63c8b4a4a776 =>
      'Could not open the cashier. Check the connection and store readiness, then retry.';

  @override
  String get pos6da6c33d741b => 'Cashier may change station';

  @override
  String get pos425d51c266d9 => 'Fast checkout, organized business';

  @override
  String get pos77410ea1a888 => 'Active shift cashier';

  @override
  String get pos62c15db2412e => 'Cashier ready for transactions';

  @override
  String get pos068673dfb8b9 => 'Cashier not identified';

  @override
  String get pos2f7d5a68ea08 =>
      'Cashier: F2 find product · F3 scan barcode · F4 pay/save table';

  @override
  String get pos57a7f26fb08f => 'Cashier: Pantoo Cashier';

  @override
  String pos354df62f6aa3(String arg1) {
    return 'Cashier: $arg1';
  }

  @override
  String pos5ca6d211882e(String arg1) {
    return 'Cashier: $arg1\n';
  }

  @override
  String get pos7d0ab1b98a4c => 'New Password';

  @override
  String get pos696ebc0f2322 => 'Current Password';

  @override
  String get posbbe72013807d => 'Password changed';

  @override
  String get pos788fce56160f => 'Catalog';

  @override
  String get pos1b8beb8b165e => 'POS Catalog';

  @override
  String get pos6b0fbc1b4d51 => 'POS catalog unavailable';

  @override
  String get posce7dda4ae52e => 'Sales Catalog';

  @override
  String get posd8a0aafdf1ac =>
      'Sales Catalog · Products come from Inventory. Master details, costs, units, batches, and location balances are managed through Inventory workflows.';

  @override
  String get pos9c558e070577 => 'Product Catalog';

  @override
  String get posb841391f4a09 => 'Could not reload catalog';

  @override
  String get pos65e32f2507ad => 'Could not load catalog. Try again.';

  @override
  String get pos46c2553e8367 =>
      'Read-only catalog. Product master changes are made by the Inventory administrator.';

  @override
  String get pos5105028f0d55 =>
      'Offline catalog does not match the store\'s stock location. Connect and reload the catalog.';

  @override
  String get posc7849a0f41eb => 'Sales catalog';

  @override
  String get posaa06cfa392d3 => 'Invalid POS profile catalog';

  @override
  String get pos7e7fbaa5b57a => 'Profile catalog unavailable';

  @override
  String get posbd69dfa44442 =>
      'Using the saved catalog. Reconnect to load the latest profiles.';

  @override
  String get posb7964404a785 => 'Category';

  @override
  String get poscc7d382913a7 => 'Inventory Category';

  @override
  String get pos61daf4364861 => 'Inventory Category';

  @override
  String get posd54d0c3d2dca => 'Report Category';

  @override
  String get pos8166ea178d93 => 'Order Category';

  @override
  String get pos75fc71e6eb87 => 'Settings Category';

  @override
  String get pos72fa10ee02ad => 'Item category';

  @override
  String get posbca5b8164d65 => 'Category added';

  @override
  String get posbb00a2fcf16f => 'Next category';

  @override
  String get pos4663bb157a02 =>
      'Could not load categories. Check your connection and retry.';

  @override
  String get pos0e3ff9e29811 => 'Inventory category';

  @override
  String get posa802a00dd246 => 'Report category';

  @override
  String get posb2bdc6965d8f => 'Notification category';

  @override
  String get pos3301c65345b9 => 'Order category';

  @override
  String get pose424eda02a56 => 'Settings category';

  @override
  String get pos01c76765186f => 'Previous category';

  @override
  String get pos15ceab423713 => 'Category not found';

  @override
  String pos93a6ccae326e(String arg1) {
    return 'Category: $arg1';
  }

  @override
  String get pos01884787d5a4 => 'To vendor';

  @override
  String get pos0e79d4505659 => 'Discount Policy';

  @override
  String get posf1240b7c6e7e => 'Privacy Policy';

  @override
  String get pose5e530d03013 => 'Operating needs';

  @override
  String get pos23ec4523a9f3 => 'Small';

  @override
  String get pos63ae75ea44f8 =>
      'Both devices need internet, but do not need the same Wi-Fi network. Bluetooth is not used for the customer display.';

  @override
  String get pos968a23422b65 => 'Excess';

  @override
  String get posefa02b180cab => 'Manage Business';

  @override
  String get pos04f02f2aee2d => 'Manage Operator PINs';

  @override
  String get pos003cad4427bd =>
      'Manage employee PINs from POS Settings without locking the administrator session.';

  @override
  String get pos09eacc17ec77 => 'Manage your customer database';

  @override
  String get pos0c42cb92c0d7 => 'Manage catalog';

  @override
  String get pose496817082e4 => 'Manage account security';

  @override
  String get pose40af8929b30 => 'Manage services';

  @override
  String get posf61f59975812 => 'Manage locations';

  @override
  String get pos42d050a1533e => 'Manage store operations and settings.';

  @override
  String get pos95eb056f1c94 => 'Manage PO receiving';

  @override
  String get posc34d57ba5437 =>
      'Manage pre-orders, item preparation, and pickup. Direct sales still finish at the cashier.';

  @override
  String get pos5bd9b7f94c75 => 'Manage reservations';

  @override
  String get pos299582cec1e1 => 'Manage stores';

  @override
  String get posfc0b2e1dfece => 'Group products';

  @override
  String get posa421ce222c82 => 'Sign Out';

  @override
  String get pos4d322b566d50 => 'Sign Out of the App';

  @override
  String get posc0f5a7fa6764 => 'Sign out of this account?';

  @override
  String get pos1bef008211b2 => 'Exit full screen';

  @override
  String get pos5687de1fa1c4 => 'Complaint / service notes';

  @override
  String pos40b1639b7bb2(String arg1) {
    return 'Complaint: $arg1';
  }

  @override
  String get posc43a6e25b712 => 'Back';

  @override
  String get pos024e89a11384 => 'Back to Cart';

  @override
  String get posa880cee60ee1 => 'Back to Sign In';

  @override
  String get pos7d9e6b1f7ba0 => 'Back to receivables';

  @override
  String get pos7ff9bb1beb64 => 'Back to sign in';

  @override
  String get pos13d986d7a714 => 'Back to purchase';

  @override
  String get pos04f4e113ab12 => 'Back to active shift';

  @override
  String get pos5c9372f2f537 => 'Change';

  @override
  String pos9346d428aef7(String arg1) {
    return 'Change    $arg1';
  }

  @override
  String posfbcfa461b741(String arg1) {
    return 'Change: $arg1\n';
  }

  @override
  String get pos0b31187ca7ce => 'Return to Stock';

  @override
  String get posa6e6096bad6e => 'Explore the cashier area';

  @override
  String get pos79e4ec31d635 => 'Vehicles';

  @override
  String posd11b0955d522(String arg1) {
    return 'Vehicle: $arg1';
  }

  @override
  String get posd0e69e9b51ec => 'Customer Satisfaction';

  @override
  String get pos517f4907a428 => 'Discrepancy decision';

  @override
  String get pos58540729c325 => 'Decision saved';

  @override
  String pos735eff437800(String arg1) {
    return 'Decision: $arg1';
  }

  @override
  String get pos3ac7e2913ec0 => 'Cart';

  @override
  String pos541eb83e5a0c(String arg1) {
    return 'Cart ($arg1)';
  }

  @override
  String get posd10f06fb91f5 => 'The cart is empty';

  @override
  String get pos98dfce1f2b6a =>
      'Net loss = disposed quantity minus recycled output';

  @override
  String get pos5fa25d549304 => 'Payment terms';

  @override
  String get pos5c7981a1e508 => 'Payment terms and priority';

  @override
  String get pos802c6998ea71 => 'Terms of Service';

  @override
  String get pos557f56ddb658 => 'Remarks';

  @override
  String get pos6d421a9a346a => 'Notes (optional)';

  @override
  String get pos1d4731ce6f06 => 'Notes *';

  @override
  String get pos6ed3ea76d4bb => 'Notes must be at least 5 characters';

  @override
  String get pos828c4805f454 => 'Server availability is checked during sync.';

  @override
  String get posb4294193d174 => 'Enter the six characters in the image';

  @override
  String get pos49ea8bd96b89 =>
      'Tap Save if the customer is not ready to pay. The order can be resumed later.';

  @override
  String get posbdeb2bbb6da0 =>
      'Tap Add Product to open the form and start preparing items for sale.';

  @override
  String get pos1e30aa18f316 =>
      'Tap Add Warehouse to open the form for your first storage location.';

  @override
  String get posfcc4b15454eb => 'Tap the highlighted area to continue';

  @override
  String get posc88fca67057b => 'Tap the highlighted element to continue.';

  @override
  String get pos3888ca3dce59 =>
      'Tap this field to search by name, SKU, code, or scan a barcode.';

  @override
  String get pos3f4aada8fe7d =>
      'Tap to select channel, price level, tax, order type, and promotion.';

  @override
  String get pos2c73aefd8a60 => 'By Weight';

  @override
  String get pos00d1624e7e8b => 'Send';

  @override
  String get pose654910117ca => 'Submit Approval';

  @override
  String get pos95ef9b85140e => 'Resend Email';

  @override
  String get pos5d44f805b296 => 'Send invoice proof to Finance';

  @override
  String get pos7eb2078b7723 => 'Send another invoice proof';

  @override
  String get posd437960909e6 => 'Send invoice photo';

  @override
  String get pos0d9901a7c98b => 'Send to';

  @override
  String get posae1729b56772 => 'Send to Supplier';

  @override
  String get posdda037ae2d4c => 'Send request';

  @override
  String get posbbc1bdc9fe7f => 'Dispatch transfer';

  @override
  String get pos6bb160cfbf81 => 'Resend';

  @override
  String get pos90138adadcb4 => 'Resubmit the same proof';

  @override
  String get pos86399cce1679 => 'Resend transaction?';

  @override
  String get pos14453ee0a3de => 'Submit for approval?';

  @override
  String get posf9fff542e06f =>
      'Dispatch → In Transit → Receive at destination';

  @override
  String posc3ea0cd9a924(String arg1) {
    return 'Dispatch: $arg1';
  }

  @override
  String get pose11f122c5a6c => 'Kitchen flow';

  @override
  String get pos3e25d43ab0d0 => 'Code';

  @override
  String get pos24b32ed17d3a => 'CAPTCHA Code';

  @override
  String get pos72e4ae972eb0 => 'Six-character CAPTCHA code';

  @override
  String get pos7e032c04b7e1 => 'Promo Code';

  @override
  String get pos546bf5e04d4a => 'Expense account code (optional)';

  @override
  String get pos682155107733 => 'Loss expense account code';

  @override
  String get pose2234af7c2a6 => 'Code matches multiple items. Select manually.';

  @override
  String get pos88c20dbb60a4 =>
      'Code matches multiple products. Select manually.';

  @override
  String get posfce6e7d87c33 => 'Code and label quantity (1–50) must be valid.';

  @override
  String get posdec99effb544 =>
      'Code must be 3–20 letters or numbers without spaces';

  @override
  String pos844214a54fe7(String arg1) {
    return 'Inventory code · $arg1';
  }

  @override
  String get posd39725beed75 => 'Code is blank or unsupported by Code 128.';

  @override
  String get pos997eb9526cf1 => 'Outlet code';

  @override
  String get posbd37069ac452 => 'Code on label';

  @override
  String get pose4280a94c63c => 'Product code not found.';

  @override
  String get pos3d00cf0d363b => 'Promo code';

  @override
  String pos5d8a179eb068(String arg1) {
    return 'Promo code    $arg1';
  }

  @override
  String get pos7cb199edf974 =>
      'Promo code could not be verified. Invoice was not saved offline.';

  @override
  String get pos66fbf8f2a3ac =>
      'Promo code could not be verified. Transaction was not saved offline; connect or remove the promotion.';

  @override
  String get pos93c1b1c32490 =>
      'Promo code not verified. Connect or remove the promotion.';

  @override
  String get pos40786c706bd8 =>
      'Promo code must be verified online before creating an invoice.';

  @override
  String get pos49e5b7b133e9 =>
      'Promo code requires server validation. Connect or remove the promotion before paying.';

  @override
  String get posbedb90d93b97 => 'Code not found at this stocktake location.';

  @override
  String get pos0805d43c642d => 'Code not found at the source location.';

  @override
  String get pos2ee4a91cbabe => 'Warehouse code';

  @override
  String get posb39d2ddfa76c => 'Visible Columns';

  @override
  String get pos32385ebb7c07 => 'Commission';

  @override
  String get pos7df1a7e7cc8c =>
      'No commissions recorded for POS transactions in this period.';

  @override
  String get pos0750e291bd60 => 'Components';

  @override
  String get posc8e53a04fdf8 => 'Could not load components. Try again.';

  @override
  String get pos8f4c585200a6 => 'Stock component not found.';

  @override
  String get posb68777628996 => 'Invalid product composition or quantity.';

  @override
  String get pos20c2bca27f3e => 'Composition consumed';

  @override
  String get pos8c991cd95ebb =>
      'Stock composition requires components with valid quantities';

  @override
  String get posb723bb628009 => 'Condition';

  @override
  String get posef072c920632 => 'Stock condition';

  @override
  String get pos76a219477066 => 'Condition/notes';

  @override
  String pos3ef623db628c(String arg1) {
    return 'Condition: $arg1';
  }

  @override
  String get posfefe3b5e56fa =>
      'Connection to the API closed before the full response was received.';

  @override
  String get posde96ca46f337 =>
      'Customer display disconnected. Create a new pairing to retry.';

  @override
  String get posc9474dc76f88 =>
      'Connection timed out. Reload; unconfirmed proofs remain saved.';

  @override
  String get pos3c2bcc062ea3 => 'Device network available';

  @override
  String get posdb3205b1b23c =>
      'Server connection lost. Web transaction has not been saved; try again.';

  @override
  String get pos3444e1c1dff0 => 'Disconnected · reconnecting';

  @override
  String pos2eda82c2246c(String arg1) {
    return 'Connection lost. Reconnecting ($arg1/3)…';
  }

  @override
  String get pos99c144670e54 => 'Could not load POS configuration. Try again.';

  @override
  String get pos49d77ea309d1 =>
      'POS configuration is not ready. Pull to reload.';

  @override
  String get pos8ae2a0e3cf19 =>
      'Could not load POS configuration. Check your connection and retry.';

  @override
  String get pos09c5005bb9e8 => 'POS configuration unavailable';

  @override
  String get pos6d555e664b59 => 'Operating configuration';

  @override
  String get pos823d61d3f0f0 => 'Operating configuration matches';

  @override
  String get pos8ee41d90bf64 =>
      'Session configuration unavailable. Try again when the service recovers.';

  @override
  String get pos67b7bd6433f2 => 'Confirm';

  @override
  String get pose170ace18250 => 'Confirm Delete';

  @override
  String get pos32e39568417f => 'Confirm New Password';

  @override
  String get pos4c8507e0ea2c => 'Confirm Sign Out';

  @override
  String get pos979b1c6d198e => 'PIN confirmation does not match';

  @override
  String get pos746fbd90103e => 'Confirm Close Shift';

  @override
  String get pos088961359018 => 'Confirm received by customer';

  @override
  String get posbdb2300bdfd3 => 'Password confirmation does not match';

  @override
  String get pos8acb91d763c0 => 'Confirm password';

  @override
  String get posf035413485d0 =>
      'Confirm the login account\'s password, then create a 4–6 digit cashier PIN.';

  @override
  String get posda41260e3e35 => 'Password confirmation does not match';

  @override
  String get pos81bad4d0ebdb => 'Confirm receipt';

  @override
  String get posd33e46cd3a38 => 'Confirm dispatched';

  @override
  String get pos83544e6c3733 => 'Confirm served';

  @override
  String get posfb7511dd7570 => 'Confirm handed over';

  @override
  String pos18a9e21cb58b(String arg1) {
    return 'Confirm $arg1';
  }

  @override
  String get posbd9d9eeacb9b => 'Contact details or notes are required.';

  @override
  String get pose196b46c270c => 'Destination supplier contact';

  @override
  String get posa7603db4ad52 => 'Supplier destination contact';

  @override
  String get pos4fa7254bb966 => 'Transaction & Pricing Context';

  @override
  String get posc7c9c2251e9e => 'Pricing context';

  @override
  String get posba1eb971cb88 => 'Real-time inventory control';

  @override
  String get pos1da5dc1946c8 => 'Unit conversions';

  @override
  String get pos830c62a13eba =>
      'Unit conversions are not available for offline transactions.';

  @override
  String get pos07a366526b53 => 'Physical unit conversions';

  @override
  String get posd78e730c904e =>
      'Unit conversions must be unique and greater than 0';

  @override
  String get poscfae9e972218 => 'Invalid unit conversion.';

  @override
  String pos2befc83ee9ee(String arg1) {
    return 'Saved conversions: $arg1';
  }

  @override
  String posa006c9daadf0(String arg1, String arg2, String arg3) {
    return 'Conversion: 1 $arg1 = $arg2 $arg3';
  }

  @override
  String get posc59d948c6451 => 'Adjustment';

  @override
  String get posbc53e9e226ce => 'Emergency Correction';

  @override
  String pos886f4075bfac(String arg1) {
    return 'Emergency correction $arg1';
  }

  @override
  String get pos6130a29de57d => 'Correct this balance';

  @override
  String get pos63100c7697f9 => 'Correct stock';

  @override
  String get pos899f41b5cc75 => 'Clear';

  @override
  String get pos6114bc6f6206 => 'Clear cart & check';

  @override
  String get posd197177a4ce2 => 'Clear cart?';

  @override
  String get pos7e23cb1f87fa => 'Clear entire cart';

  @override
  String get posd84cb32dc73b => 'Leave blank for an automatic number';

  @override
  String get pos9e12621cc945 => 'Credit';

  @override
  String get posb6b8590ca28b => 'Poor Quality';

  @override
  String get pos4e21022f6bb3 => 'Auto-Lock After (minutes)';

  @override
  String get pos707a549e35fe => 'PIN lock disabled according to POS policy.';

  @override
  String get pos79508d5da62e => 'POS Lock';

  @override
  String get posd369c03ef692 => 'Lock When App Is in Background';

  @override
  String get posfcafa7a594c1 =>
      'Lock the screen, then sign in again with the configured operator and PIN.';

  @override
  String get pos5589ac4ca19e => 'Reduce';

  @override
  String get pos0b769ce5980a => 'Custom';

  @override
  String get pose7ef668236c8 => 'REPORTS';

  @override
  String pos366edac1e231(String arg1) {
    return 'Barcode Label $arg1';
  }

  @override
  String pos58df45e9d2a1(String arg1, String arg2) {
    return 'Labels sent: $arg1/$arg2';
  }

  @override
  String posd56f5ea7493b(String arg1) {
    return 'Label $arg1';
  }

  @override
  String get pos844f8a723473 => 'Other';

  @override
  String get pos55d1ade4d4df => 'Pro forma attachment up to 10 MB';

  @override
  String get pos13c41f4e7cde => 'Attach pro forma (optional)';

  @override
  String get pos1416db327cbc => 'Landed Cost';

  @override
  String get pos8aa2435c809f => 'Step 1 of 3 · Business Profile';

  @override
  String get posdc6bcae9bf52 => 'Step 1 · Stock location ready';

  @override
  String get pos139e5c7d4542 => 'Step 2 of 4 · Operating Features';

  @override
  String get pos64db087956e5 => 'Step 2 · Active POS store';

  @override
  String get pos553e7bc38201 => 'Step 2 of 3 · Transaction Defaults';

  @override
  String get pos21ebb9cb6982 => 'Step 3 · Sales catalog';

  @override
  String get pos9bffdb32cde8 => 'Step 3 of 3 · Inventory Validation';

  @override
  String get pos019fc97e4540 => 'Step 6 · Cashier operator PIN';

  @override
  String pos20c79e7542df(String arg1) {
    return 'Step 6 · $arg1';
  }

  @override
  String pos73c8c1400ddb(String arg1) {
    return 'Step $arg1';
  }

  @override
  String pos2c4c63238b07(String arg1, String arg2) {
    return 'Step $arg1 · $arg2';
  }

  @override
  String get pos429121b48c9c => 'Direct';

  @override
  String get pos18b46d7a8e8d => 'Ready-made / no kitchen';

  @override
  String get pos5f04d3d18b1e => 'Submit for approval immediately';

  @override
  String get pos45fb05bf47a1 => 'Complete immediately on dispatch';

  @override
  String get pos5636299a6637 => 'Continue';

  @override
  String get pos5bcbc797a7ea => 'Continue';

  @override
  String get posabf7ce4c1009 => 'Continue with Google';

  @override
  String get pos9d5e28c99300 =>
      'Continue to Stock & Units to set the base unit and inventory rules.';

  @override
  String get posb318e3331d05 => 'Continue cancellation';

  @override
  String get pos85f2ed654282 => 'Continue payment';

  @override
  String get posc9b2dead5600 => 'Continue setup';

  @override
  String get pose0b6de8be3dc =>
      'Resume that shift, or close it after reconciling cash and offline transactions. Shifts are not closed automatically.';

  @override
  String get posdc72f24826cc => 'Landscape';

  @override
  String get posebfe5e0b4b99 => 'Floor / Level';

  @override
  String get pos90570335cffb => 'Floor 2';

  @override
  String get pos4ea259b1329d => 'Reports';

  @override
  String get pos93c1f2ea2f12 => 'Vehicle Report';

  @override
  String get pos96d3857baa1c => 'Commission Report';

  @override
  String get pose945841afe4b => 'Comprehensive Reports';

  @override
  String get posd1dcfd64446e => 'Sales Report';

  @override
  String get pos5738a26d9387 => 'Movement Report';

  @override
  String get posa8b6fd8161a2 => 'Stock Report';

  @override
  String get posf6944142501b => 'Void Report';

  @override
  String get pos01faa16d9dd8 =>
      'Reports update directly from POS transactions.';

  @override
  String get pos687d9b37d5f5 =>
      'Discrepancy report submitted; awaiting a separate reviewer';

  @override
  String get pos681e73127873 =>
      'This report has been decided. Reload the list.';

  @override
  String get pos36b2c0cff56a => 'Could not load report';

  @override
  String get pos53ad13d0b210 => 'Report shortage/damage';

  @override
  String get pos0a96ed2b8247 => 'Report transfer discrepancy';

  @override
  String get posf5c101a0c210 => 'Laundry';

  @override
  String get pos64aceffd3bed => 'Services';

  @override
  String get posb79eff83a8b7 => 'Services (no stock)';

  @override
  String get pos3696a417e271 => 'Quick Service';

  @override
  String get pos48ab7ebb7bb8 => 'Quick service';

  @override
  String get pos416962365efd =>
      'Beauty services, reservations, staff, and care products';

  @override
  String get pos1b3d7b3d9d3f =>
      'Serve customers, monitor stock, and manage sales in one place.';

  @override
  String get pos16cd7168e6ae => 'Customer Display';

  @override
  String get pos8978d15ec397 => 'Customer display';

  @override
  String get pos2af1260728c9 =>
      'Customer display over local Wi-Fi is only available in the Android app.';

  @override
  String get pos672d2762260b => 'Customer display connected';

  @override
  String get pos4b2f7033dd09 => 'Full screen';

  @override
  String get pos677be7603ea9 =>
      'Full screen could not be opened. Try again in this device\'s browser.';

  @override
  String get posb68df8c1bbf2 => 'Display connected';

  @override
  String get posb7a2f669650b => 'Paper Width';

  @override
  String get posfd1f28e18dec => 'Complete';

  @override
  String get posaa1ec1566c21 => 'Complete your Pantoo account';

  @override
  String get pos1cbe776efda3 => 'Complete service details before continuing.';

  @override
  String get pos6b493cb6bbf1 =>
      'Complete the required fields and save to make the product available at the cashier.';

  @override
  String get pos1899cac656d5 => 'Complete the location hierarchy';

  @override
  String get pos6fb687df48cb => 'Complete your account details to continue.';

  @override
  String get pos0f2a6d363a37 => 'Complete sales information';

  @override
  String get pos4c4a81c0a45c =>
      'Complete the phone number and consent to create an account.';

  @override
  String get pos5c72e643bc37 => 'Complete before saving';

  @override
  String get pos9494ee1e398a =>
      'Complete supplier, description, amount, funding source, and expense account.';

  @override
  String get posdcd63112b43a => 'Enter valid times and at least 1 guest.';

  @override
  String get pos60e7fbd2c6f8 => 'Disconnect Bluetooth printer';

  @override
  String get posa17fe7adeee7 => 'Remove voucher';

  @override
  String get posfb406180b6c2 => 'Remove voucher from order?';

  @override
  String pos3c6acbdc6172(String arg1) {
    return 'Remove voucher $arg1';
  }

  @override
  String get pos28f2742a5e35 => 'Price Level';

  @override
  String get posd11d31a1fb97 => 'Active Price Levels';

  @override
  String get pose4887ee2eec0 => 'Default Price Level';

  @override
  String get posf85112657fba => 'Price level';

  @override
  String posb3c012f547d2(String arg1) {
    return 'Level $arg1';
  }

  @override
  String get pos8bd638497107 => 'Skip';

  @override
  String get pose75a6809ca54 => 'View / Print table QR';

  @override
  String get posa8f9f7a09784 => 'View Details';

  @override
  String get pos2adf97615584 => 'View All';

  @override
  String get pos9f38e2a2710a => 'View Supplier Bills';

  @override
  String get pos1c9522defd65 => 'View proof';

  @override
  String get pos2557d2ec360e => 'View details';

  @override
  String get pos7046318792e6 => 'View active orders';

  @override
  String get pos9527dd654568 => 'View all';

  @override
  String get posb63f1d0ba8de =>
      'Google sign-in was unsuccessful. Try again or use your email and password.';

  @override
  String get poscfe2976f2ac1 =>
      'Google sign-in failed. Check your connection and try again.';

  @override
  String get posfebd44020ff0 =>
      'Google sign-in was unsuccessful. Please try again.';

  @override
  String get pos78a1383b4dc9 =>
      'Google sign-in is taking too long. Check your connection and try again.';

  @override
  String get pos81fe77ec85c9 => 'Sign-in failed.';

  @override
  String get pos5e8dd9952d58 => 'Sign-in failed. Try again.';

  @override
  String get pos4485b4994161 => 'Sign in now and experience the convenience';

  @override
  String get pose43d612e11f1 => 'Sign Out';

  @override
  String get pos34c87188d721 => 'Sign out of account';

  @override
  String get pos273a69e49c76 => 'Transit Location';

  @override
  String get pos13f745d88bdc =>
      'Source and destination locations must be different.';

  @override
  String get posd2f4fea361d1 => 'Location not recorded';

  @override
  String get posf8e78d9857e3 => 'Branch location not configured';

  @override
  String get pos5cb6e8758fbd => 'Incident location';

  @override
  String get posee8e873d108d =>
      'Receiving location differs from the stock destination recorded in the PO';

  @override
  String get pos83744b737263 => 'Sales location';

  @override
  String get pos0c712232d2cf => 'Sales location / warehouse';

  @override
  String get posf513e88bc46a => 'Movement location';

  @override
  String get pos89306eb4ab8c => 'Snapshot location (locked)';

  @override
  String get pos5dedca68146c => 'Stock location';

  @override
  String get posdfca62413fe4 => 'PO receiving stock location *';

  @override
  String get pos25894be8623d => 'Stock location ready';

  @override
  String get pos3abb25ef4211 => 'Stock location not recorded';

  @override
  String get posa94470fe0694 =>
      'Store stock location is not saved. Connect to prepare the offline catalog.';

  @override
  String pos2843f97128cf(String arg1) {
    return 'Stock location $arg1';
  }

  @override
  String get pos239846258153 => 'Source location';

  @override
  String get pos5ccdecdb4fd8 => 'Destination location';

  @override
  String get pos2e053f59095f =>
      'Main location • building/room/rack not specified';

  @override
  String pos86d285bf18f2(String arg1) {
    return 'Location: $arg1';
  }

  @override
  String get pose065b60384ad => 'Paid';

  @override
  String get pos83125cc87a7b => 'MA';

  @override
  String get pos2162e65b6e55 => 'MANAGEMENT';

  @override
  String get pos83255691db80 => 'PARTNERS';

  @override
  String get pos09dab143c57f => 'MRO Supplies';

  @override
  String get posf2f24bd8b491 => 'Dine In';

  @override
  String get pos91aa7317a575 => 'Dine In (Select Table)';

  @override
  String get pos23b1e38da612 => 'Dine In (No Table)';

  @override
  String get pos0b8d01beaa49 => 'Dine In (with table)';

  @override
  String get posf560263f3112 => 'Dine In (without table)';

  @override
  String get pos27711cc5f4a8 => 'Dine in';

  @override
  String get pos1c37b48fea67 => 'Dine in · No table';

  @override
  String get pos2c1d80834aac => 'Dine in · no table';

  @override
  String get pos13ad040ce070 => 'Max. Discount (Rp)';

  @override
  String get posee50303e2a5e =>
      'Up to 100 results. Enter a name/code to narrow the search.';

  @override
  String pos27801602c212(String arg1) {
    return 'Maximum remaining $arg1';
  }

  @override
  String get pos1edebd1f9bf6 => 'Management';

  @override
  String get pos18928d792efc => 'Stock Management';

  @override
  String get posdc5278c51c2f => 'Integrated Management';

  @override
  String get pos4e836fdc2572 => 'Manual';

  @override
  String get pose2d1385525c4 => 'Manual + Promotion';

  @override
  String get posa597b84b2833 => 'Manual only';

  @override
  String get pos983095c0ea49 => 'Marketplace';

  @override
  String get posf2dd30734a6a => 'Sign In';

  @override
  String get pos2a5d8a5edfc7 =>
      'Enter the cashier PIN before saving or restoring a return.';

  @override
  String get posa791716d343e => 'Sign In to Mobile POS';

  @override
  String get pos5e8a419ae266 => 'Sign In as Cashier';

  @override
  String get pos51f157329714 => 'Enter the operator\'s own 4–6 digit PIN.';

  @override
  String get pos9130978b1b96 => 'Enter Invoice No...';

  @override
  String get posd729b5d8f153 => 'Enter the employee\'s 4–6 digit PIN';

  @override
  String get pos7c3de4226e10 =>
      'Enter the cashier PIN before checking the shift.';

  @override
  String get pos3f0e8b9c8b17 => 'Enter a valid number';

  @override
  String get pos8f3a1bf071bb => 'Enter a valid email';

  @override
  String get pos4de3692f58a8 => 'Enter the six CAPTCHA characters';

  @override
  String get pos4ebfb06378c5 =>
      'Enter the price paid by the customer. Purchase/cost price can be added to calculate margin.';

  @override
  String get pos0a979f003a0b => 'Enter a valid payment amount.';

  @override
  String get pos2a9e22d410da =>
      'Enter opening cash based on the physical cash in the drawer for easier reconciliation.';

  @override
  String get pos04f4fcb6b340 => 'Enter the voucher or promo code to apply';

  @override
  String get posdb3a72dc94d7 => 'Enter at least 2 characters';

  @override
  String get pos7844ce0f93f7 => 'Enter a phone number with 8–15 digits.';

  @override
  String get pos59f2894d2bfa => 'Enter destination number';

  @override
  String get posfa444fe1d6d7 => 'Add stock through the correct workflow';

  @override
  String get poscff23131c29d => 'Enter valid stock';

  @override
  String pos17bfd9a177d7(String arg1, String arg2, String arg3) {
    return 'Matching: $arg1 · Due: $arg2\nOutstanding: $arg3';
  }

  @override
  String get pos7e149ab136a9 => 'Tables';

  @override
  String posfa22ff918702(String arg1) {
    return 'Table \"$arg1\" updated';
  }

  @override
  String poscef4c604164c(String arg1) {
    return 'Table \"$arg1\" added';
  }

  @override
  String get pos40cab72a9546 => 'Table deleted';

  @override
  String get pos4ced6ce7acc7 =>
      'This table has active orders and cannot be deleted.';

  @override
  String get posb9acaf793c8e => 'Table not found';

  @override
  String pos29db2f117897(String arg1) {
    return 'Table $arg1';
  }

  @override
  String posc617cc586a0c(String arg1) {
    return 'Table · $arg1';
  }

  @override
  String get pos305a15c9d811 => 'Tables, kitchen, and delivery';

  @override
  String get pos2b24399b7752 => 'Verifying draft...';

  @override
  String get pos6853c98a6f43 => 'Member';

  @override
  String get posa8891bc0532c => 'Checking open POs for this item…';

  @override
  String get pos3347fa44e993 => 'Checking offline queue...';

  @override
  String get pos7835f13bdca6 => 'Checking receipts...';

  @override
  String get pos1a72fe1062a9 => 'Checking latest transfer...';

  @override
  String get pos2e34c1191665 => 'Checking...';

  @override
  String get pos048ecc7562e7 => 'Checking…';

  @override
  String get pos15403184d9b0 =>
      'Requires permission to add suppliers. Tax details and address can be completed on the web.';

  @override
  String get posf4b4e9473648 => 'Online verification required.';

  @override
  String get pos5aa9f2c1320e => 'Moving order';

  @override
  String get posd393b9b0ef8e => 'Moving kitchen order';

  @override
  String get pos4f8ed6e388f9 => 'Revision requested';

  @override
  String get posbed1b72018c1 => 'Preparing dashboard...';

  @override
  String get pos955ddd5b0913 => 'Processing and updating return...';

  @override
  String get pos6264e018ce66 => 'Processing transfer...';

  @override
  String get pos5f2061cbdf8f => 'Processing...';

  @override
  String get pos5dd5b804c0b6 =>
      'Loading receipt settings… You can still view this page.';

  @override
  String get posdb6901fef6ca => 'Loading transactions...';

  @override
  String get pos900c6d4b2e5b => 'Verifying account with Pantoo POS…';

  @override
  String get posa301c88d72cd => 'Showing the PDF layout guide';

  @override
  String posa71587490499(String arg1) {
    return 'Recording receipt for transfer $arg1...';
  }

  @override
  String get pose6d19189f617 => 'Printing receipt...';

  @override
  String get pos2df640ba2491 => 'Printing receipt…';

  @override
  String get posce247c3f955f => 'Printing…';

  @override
  String get posc614b769dbbc => 'Urgent';

  @override
  String get pos2225aa4fce9b =>
      'Determines this customer\'s product price list';

  @override
  String get posee48fb2e096b => 'Determines product pricing for this customer';

  @override
  String posbffaaa8b679c(String arg1) {
    return 'Submitting PO $arg1...';
  }

  @override
  String get poscda80f09a6a8 => 'Got it';

  @override
  String get pos609df42fd4d8 => 'Reconnecting customer display…';

  @override
  String get pos787dc4aadf40 => 'Connecting…';

  @override
  String get pose1010f9f4fe2 => 'Sending...';

  @override
  String get pos00df34064d27 => 'Sending…';

  @override
  String pos7ff57871e031(String arg1) {
    return 'Retrying journal entry $arg1...';
  }

  @override
  String get posbf0c0c2094f3 => 'Uploading...';

  @override
  String get pos9f17fa169c88 =>
      'Rejecting releases the goods for reprocessing. Reporters cannot decide their own reports.';

  @override
  String get pos57f5f5efbc59 => 'Menu';

  @override
  String get pos45718cc63b3f => 'Menu not found';

  @override
  String get posbcc4a60693b2 => 'Pending';

  @override
  String get posb651ecbc1c60 => 'Awaiting kitchen';

  @override
  String get posf3057c1bd132 => 'Waiting for the cashier to add products.';

  @override
  String get pos4c25b91d5275 => 'Awaiting confirmation';

  @override
  String get pos226af7add369 => 'Awaiting receipt';

  @override
  String get pose3d4131eda62 => 'Awaiting handover';

  @override
  String get pos709aa770adfc => 'Waiting for device…';

  @override
  String get pos8359f127193c => 'Awaiting approval';

  @override
  String get pos53a70fe7d7f8 => 'Waiting for Google account selection…';

  @override
  String get pose398c2c079bf => 'Awaiting processing';

  @override
  String get pos7acfde6c8cc9 => 'Awaiting response';

  @override
  String get pos4775986a2641 => 'Awaiting server sync';

  @override
  String get pos2f330d8f1f39 => 'Awaiting supplier';

  @override
  String get pos2e76b446b2a7 => 'Completing registration…';

  @override
  String get pos833c65e9f213 => 'Preparing Pantoo POS…';

  @override
  String get pos090296b76c46 => 'Preparing Google sign-in…';

  @override
  String get pos36dd6d6b11f7 => 'Preparing…';

  @override
  String get posf16f7f9512ac => 'Saving...';

  @override
  String get pos92e2482fd49f => 'Saving…';

  @override
  String get pos2281e868fd1a => 'Brand';

  @override
  String get pos5ac33f2c588b => 'Method';

  @override
  String get pos2a5040bd1051 => 'Payment Method';

  @override
  String get posac8a50ffd071 => 'Default Payment Method';

  @override
  String get pos53eb1a623ade => 'Payment method';

  @override
  String pos37949a5da433(String arg1) {
    return 'Payment method: $arg1';
  }

  @override
  String get pos1e76e9e68291 => 'Receiving method';

  @override
  String get posfd53d4d680b7 => 'Method for the paid portion';

  @override
  String posc1ee701a402d(String arg1) {
    return 'Method: $arg1';
  }

  @override
  String posb0b20c64aae6(String arg1, String arg2, String arg3) {
    return 'Method: $arg1 · Installment: $arg2$arg3';
  }

  @override
  String get pos2a72463de982 => 'Min. Purchase (Rp)';

  @override
  String pos2642c8d7b316(String arg1) {
    return 'Min. purchase $arg1';
  }

  @override
  String get posa4c67a20f600 => 'This Week';

  @override
  String get pos24e468e21005 => 'At least 10 characters';

  @override
  String get pos7218dad7779c =>
      'At least 2 methods, each amount greater than 0, with an exact total.';

  @override
  String get pos254f9747a60f => 'At least 5 characters';

  @override
  String get pos097715fd4c9e => 'Minimum Cash Transaction (Rp)';

  @override
  String get posbe17257a299d => 'Minimum cash transaction cannot be negative.';

  @override
  String get pos5d398eef3ecc => 'Minimum';

  @override
  String pos9e159b1c2295(String arg1) {
    return 'Minimum cash transaction $arg1. Choose another method or increase the transaction amount.';
  }

  @override
  String pos543e961a6128(String arg1) {
    return 'Minimum $arg1';
  }

  @override
  String get pos40adfaa035d1 =>
      'Ask an authorized staff member to create a stocktake for this location.';

  @override
  String get pos43b98f83f50d => 'Request revision';

  @override
  String get posf2505d4015d5 => 'Partners';

  @override
  String get pos8bb4ef5d9c6d => 'Inactive Partner';

  @override
  String get posd242e923b109 => 'Mobile POS Pantoo';

  @override
  String get posab370d25ce9c => 'Mobile POS Pantoo (Dev)';

  @override
  String get pos163fa4235845 => 'Mobile POS Pantoo (Staging)';

  @override
  String get pos2df17605c8ff => 'Mobile POS Payment';

  @override
  String get pos70a4f89b86e6 => 'Bluetooth Print Mode';

  @override
  String get pos13c8ce146162 => 'PDF debug mode';

  @override
  String get pos4bc940c602c3 =>
      'View-only mode. Manage POS Settings permission is required to save changes.';

  @override
  String get pos5c174268db6c =>
      'View-only mode. Changes require Manage POS Settings permission.';

  @override
  String get pos910c6d384f34 =>
      'Offline mode · These figures are estimates from history saved on this device.';

  @override
  String get pose9e5220de240 => 'Cashier shift mode';

  @override
  String get posd014b242f2da =>
      'Store shift mode is not saved. Connect and reload the store once before continuing offline.';

  @override
  String get posff82cf4bada4 =>
      'Shift snapshot mode unavailable. Verify the shift online first.';

  @override
  String get pos650e36cf76a5 => 'Model / type';

  @override
  String get pos3cc6edc5685a => 'Service model';

  @override
  String posbdc2845195b0(String arg1) {
    return 'Model: $arg1';
  }

  @override
  String get posc46febb3ad42 => 'Complete the required fields (Name and Price)';

  @override
  String get posc8e79b99f056 => 'Please wait a moment';

  @override
  String pos3bcc4a44a905(String arg1, String arg2) {
    return 'Load more ($arg1/$arg2)';
  }

  @override
  String get posf7a8990dc6a0 => 'Load more';

  @override
  String get pos139b85ada048 => 'Reload';

  @override
  String get pos86fa0b971ba4 => 'Reload queue';

  @override
  String get posb272a8e4df9b => 'Reload catalog';

  @override
  String get posaa8e77425c74 => 'Reload categories';

  @override
  String get pos1a640a1a1a7b => 'Reload printers';

  @override
  String get posc143701b68e1 =>
      'Reload the bill before recording another payment.';

  @override
  String get posc6835bfee9cb => 'Reload the bill before retrying payment.';

  @override
  String get pos2bf3a79eb582 => 'Reload the bill before the next payment';

  @override
  String get pos9ec2d52493d6 => 'Easy to Use';

  @override
  String get pos44164b908ecb => 'Start';

  @override
  String get posb22588b3cc58 => 'Start Selling';

  @override
  String get pos6abcbebc3318 => 'Get Started Faster';

  @override
  String get pos7c4bd6c9b22d => 'Get Started';

  @override
  String get pos48ab3b2f0e33 => 'Start counting this item';

  @override
  String get posc22730cb8b24 => 'Start guide';

  @override
  String get pos0093d2ea6be6 => 'Start cashier guide';

  @override
  String get pos1801629853aa => 'Start processing';

  @override
  String get posb90f6133997b => 'Reservation start *';

  @override
  String get pos37304c670c37 => 'Start cashier shift';

  @override
  String get pos8062023c1687 =>
      'Start your Pantoo Unlimited trial and set up your store in a few steps.';

  @override
  String get posb949f55ba289 => 'Stock Transfers';

  @override
  String get pos154f8be699fa => 'Stock transfer saved';

  @override
  String get pos7f4d6bf4adad => 'Could not receive stock transfer';

  @override
  String get pos00d20ca3cb52 => 'GraphQL mutation failed';

  @override
  String get pos79d12c107a32 => 'Name';

  @override
  String get posb101d3947323 => 'Cashier Name';

  @override
  String get pos8e78fc4ac38b => 'Table Name';

  @override
  String get pos4eccf1679992 => 'Customer Name';

  @override
  String get pos67c56ac125b6 => 'Product Name';

  @override
  String get pos783aacf14a0e => 'Promotion Name';

  @override
  String get pos50188da51884 => 'Store / Outlet Name';

  @override
  String get posadaa66a604ef => 'Business/Organization Name';

  @override
  String get posddc01a706e19 => 'Item name or code';

  @override
  String get pos7cb67ac49563 => 'Name or phone number';

  @override
  String get pos2cc7aa59412b => 'Location name and address';

  @override
  String get pos397e8d44d9fb => 'Warehouse name and address are required';

  @override
  String get pos59e181097852 =>
      'Your name and email come from your Google account. Add a phone number to continue.';

  @override
  String get posbc94b959088f => 'Name and selling price are required';

  @override
  String get pos3b70768d4a70 => 'This name is shown as the saved order title.';

  @override
  String get pos8f4ec64c487b =>
      'Organization name unavailable for payment proof';

  @override
  String get poseadc7dc709ce => 'Organization name unavailable for PO document';

  @override
  String get pos458b202df966 => 'Category name';

  @override
  String get posc35873bafe84 => 'Full name';

  @override
  String get pos715ed13a07ec => 'Name cannot exceed 200 characters';

  @override
  String get pos99e0f9c80f34 => 'Table name';

  @override
  String get pos7f62288a5370 => 'Table name is required';

  @override
  String get pose22f47c2bafa => 'Name must be at least 3 characters';

  @override
  String get posc031fef2c068 => 'Outlet name';

  @override
  String get pos21cafc4df8c5 => 'Customer name';

  @override
  String get poscf7ab6193fcb => 'Customer name is required';

  @override
  String get pos8de772a9999c => 'Order name';

  @override
  String get posa19b14d84330 => 'Product name *';

  @override
  String get posfb1952bd2dd8 => 'Supplier name *';

  @override
  String get pos8477380609e5 => 'Supplier name must be at least 2 characters';

  @override
  String get pos32fe40c439ea =>
      'Business or organization name must be at least 3 characters';

  @override
  String get pos488b5904e23a => 'Name is required';

  @override
  String get pos4a8e2d02dfb4 => 'Warehouse name *';

  @override
  String get pos471299409740 => 'Name, code, or barcode';

  @override
  String get posb3b972e0dfc0 => 'Name, code, and sales location are required';

  @override
  String get posb96e0062842d => 'Later';

  @override
  String get pos34a5d7a1b7ce =>
      'Navigation: Tab / Shift+Tab to move, Enter or Space to select.';

  @override
  String get pos66a1e43c0a09 => 'Net 30';

  @override
  String get posed50c264b6f0 => 'Net 45';

  @override
  String get posd964ac944cda => 'Net 60';

  @override
  String get pos10b28cd6b026 => 'Net 90';

  @override
  String get pos85fa51601fca => 'Discount Value (%)';

  @override
  String get pos2a1731d0a48c => 'Discount Value (Rp)';

  @override
  String get pos86f56874ed7a => 'Return Value (net)';

  @override
  String get pos7e2564a5f6c8 => 'Stock Value';

  @override
  String get pos81751335f5f1 => 'The new value equals the current balance';

  @override
  String get posf723f99a2d34 => 'Discount value is required';

  @override
  String posec83af4cb31d(String arg1) {
    return 'PO No: $arg1';
  }

  @override
  String get posecd4d34e4587 => 'Transaction No.';

  @override
  String get posb8b9f1367ad6 => 'No.';

  @override
  String get pose0a60dd8f90d => 'Order No.';

  @override
  String get pos299fec51b2e6 => 'License plate / unit ID';

  @override
  String get posd6e29beb91fe => 'No: INV-20260909-001';

  @override
  String posded34ba7cec1(String arg1) {
    return 'No: $arg1';
  }

  @override
  String get pos1795d163388f => 'Amount';

  @override
  String pos75918812dfbd(String arg1) {
    return 'Amount (max. Rp$arg1)';
  }

  @override
  String get pos2125c9c5afc2 => 'Down payment amount';

  @override
  String get pos590738f070c7 => 'Fixed Amount (Rp)';

  @override
  String get pos08d381cde90d => 'Actual amount (Rp)';

  @override
  String get pos967052976a85 => 'Cost amount (Rp)';

  @override
  String get pos7c122c58a738 => 'Cost must be a positive whole rupiah amount';

  @override
  String pos7596519ab293(String arg1) {
    return 'Amount must be greater than zero and cannot exceed $arg1.';
  }

  @override
  String get pos0cfda8058a7d => 'Invoice Number';

  @override
  String get pos1b3f5700a70c => 'PO Number';

  @override
  String get pose625eaba682f => 'PO number / supplier';

  @override
  String get pos9ec5ed9753e3 => 'Business/Organization Phone Number';

  @override
  String get pos9aea5ac737a1 => 'WhatsApp Number';

  @override
  String get pos893df9598db8 => 'Batch number (optional)';

  @override
  String get pose0d718d0a94b => 'Batch number *';

  @override
  String posfe43073929cf(String arg1) {
    return 'Batch number and expiry date for $arg1 must both be filled in';
  }

  @override
  String poscc7d32a39de7(String arg1) {
    return 'Batch number and expiry date for $arg1 are required';
  }

  @override
  String get posd60ca2aeac57 => 'Receipt proof / reference number';

  @override
  String get pos53d8cfb1d872 => 'Document number copied';

  @override
  String get posfb635bb270e3 => 'Invoice number (optional)';

  @override
  String get pos50cf5c6f8843 => 'Invoice number cannot exceed 120 characters';

  @override
  String pos810ac1454f9b(String arg1) {
    return 'Server order number: $arg1. Check items, total, and table before marking the review complete. Do not create a replacement order.';
  }

  @override
  String get posd4b1fb67c48e => 'Reference number (optional)';

  @override
  String get pos9ff1720d219e => 'Return number copied';

  @override
  String get posb75e90b2eb7a =>
      'An item\'s serial number cannot be used on two lines.';

  @override
  String get pos924623adb22d => 'Serial number is not part of this transfer.';

  @override
  String get pos2a23699fd244 => 'Dispatched serial numbers (one per line)';

  @override
  String get pos42ee73368f4d => 'Delivery note number (optional)';

  @override
  String get posf2df3517c26b => 'Phone number';

  @override
  String get posa61d7dc8457d => 'Phone number must contain 8–15 digits';

  @override
  String get pos5be049bc5180 => 'Phone number is required';

  @override
  String get posed25485938dd => 'Non-Member';

  @override
  String get pos609449ca31c3 => 'Inactive';

  @override
  String get pos1d31e323e7a9 => 'Non-stock';

  @override
  String get pos45e118d0563e => 'Normal';

  @override
  String get pos624d215cd123 => 'Notifications';

  @override
  String get pos76be91279516 => 'Could not update notifications';

  @override
  String get pos3950c303ce3f => 'Operating notifications';

  @override
  String get pos7d0d951cd306 => 'Service item';

  @override
  String get posb2d8d9f91c27 => 'Vehicle item/type';

  @override
  String get pose01fa717bacc => 'Offline';

  @override
  String get pos451617e30393 =>
      'Offline · saved catalog only, may be incomplete';

  @override
  String posfd312a360b1e(String arg1, String arg2) {
    return 'By $arg1$arg2';
  }

  @override
  String get pos4e970421d303 => 'Revenue';

  @override
  String get pos63383c0e6b7b => 'Shipping';

  @override
  String get pos06ac9575d123 => 'Shipping cost';

  @override
  String get posc3e839df6084 => 'Online';

  @override
  String get pos31135b0c022b =>
      'Queue operation failed. Reload to check its status.';

  @override
  String get pos7c554fb93f2a =>
      'This operation is not available in the active API version.';

  @override
  String get posde3d00f8991f => 'Could not process operation';

  @override
  String get pos02eaee2e25a6 => 'Inventory operation failed';

  @override
  String get pos425f34356895 => 'Operations';

  @override
  String posf749a4f6a690(String arg1) {
    return 'Active operator: $arg1';
  }

  @override
  String get pos57fc2f64757a => 'Operator changed during shift verification';

  @override
  String get pos04116e2c9dd5 => 'Operator changed. Reload the return page.';

  @override
  String get pos6d7d771d7ac4 => 'Operator changed. Check the shift again.';

  @override
  String get pos9844e85a16c2 =>
      'Operator changed. Restore using the original cashier.';

  @override
  String get pos10b91cdcb5b9 => 'Cashier operator';

  @override
  String get posb4caca3a4305 => 'Cashier operator verified.';

  @override
  String get pos8f47d27a760e =>
      'Stocktake status changed. Go back and reload the list.';

  @override
  String get posd4c5cc9a4011 => 'Stocktake not found.';

  @override
  String get pos94953b7a3b93 => 'More options: payment, discounts & costs';

  @override
  String get posb0e96c170c53 => 'Advanced purchase options';

  @override
  String get pos88b0caa86d35 => 'Payment options';

  @override
  String get poscf048762964b => 'Optional';

  @override
  String get pos247219f1e8ec => 'Optional for this item';

  @override
  String get pos9868b6f7cd56 => 'Optional, to limit excess inventory';

  @override
  String get pos1d75774c0f96 => 'Order';

  @override
  String pos46179ba2b7f3(String arg1) {
    return 'Online Orders ($arg1)';
  }

  @override
  String get posafd54e4e8409 => 'Service order';

  @override
  String get pos9f001a135526 =>
      'Saved orders can be resumed from Order List or History.';

  @override
  String get pos3312abcca494 => 'Orientation';

  @override
  String get pos39eae302d6a8 => 'Authorize & Continue';

  @override
  String get pos451bde271c3c => 'Expired Item Authorization';

  @override
  String get posb727f0a4d627 =>
      'Supervisor PIN authorization requires a server connection. Connect the device and retry the transaction.';

  @override
  String get posc28c999070af => 'Outdoor';

  @override
  String get posdcd76e2dcb71 => 'Linked POS outlet';

  @override
  String get pos34e845713ad1 => 'Jakarta Central Outlet';

  @override
  String get posdbab7c41f127 => 'Outlet deleted';

  @override
  String get pos2d5a92222852 => 'Outlet saved';

  @override
  String get posc8b97c065670 =>
      'The active shift\'s outlet is unavailable for sales. Ask a supervisor to check access and stock location.';

  @override
  String get pos8d1ce322c4eb =>
      'The active shift\'s outlet is not in the access list. Ask a supervisor to check outlet access; do not create a replacement shift.';

  @override
  String posb3f4a442d275(String arg1) {
    return 'Saved outlet ($arg1)';
  }

  @override
  String get pos48ed07b336e8 => 'Outlet not found';

  @override
  String pos8c29bd885f11(String arg1) {
    return 'Outlet: $arg1';
  }

  @override
  String get pos489422d10046 =>
      'Overrides apply only to permitted non-consumable products in the inventory master. The device must be online and a supervisor must provide a PIN and audit reason.';

  @override
  String get pose5dc3f463927 => 'CANCELLATION IN PROGRESS';

  @override
  String get posabafacd8728c =>
      'CANCELLATION IN PROGRESS - NOT VALID PAYMENT PROOF';

  @override
  String get pos9df33ab5c1be => 'BUYER';

  @override
  String get posc0d021d95ace => 'PURCHASING';

  @override
  String get pos4886f4978ab5 => 'SETTINGS';

  @override
  String pos8005cfd2ce83(String arg1) {
    return 'WARNING: Expired goods sold with authorization. Reason: $arg1';
  }

  @override
  String get pos0ad4164958bd =>
      'PINs for other accounts must still be created or reset by a POS administrator.';

  @override
  String get posa401eb1a3917 => 'New PIN';

  @override
  String get posf646e7f70118 => 'New PIN (4–6 digits)';

  @override
  String get pose836d8ff248d =>
      'Create a PIN for your login account or have it managed by a POS administrator.';

  @override
  String get pos9e179dd946e0 => 'PIN can only be created for the login account';

  @override
  String get pos51ef2be0d90a => 'PIN must contain 4–6 digits';

  @override
  String get pos18e45faa12d7 =>
      'Employee PIN not created. Contact a POS administrator.';

  @override
  String get pos49d3706211c0 => 'Transaction creator\'s cashier PIN';

  @override
  String get pos51801b9f543e => 'PIN keypad';

  @override
  String get posf0051b79abf9 =>
      'Offline PIN unavailable on this device. Verify the operator online first.';

  @override
  String get posee711e78127c => 'Cashier operator PIN';

  @override
  String get pos245897c8bf93 => 'Incorrect PIN';

  @override
  String get pos0d84c7cb0ab3 => 'Supervisor PIN';

  @override
  String get posee4f932a81c6 => 'Supervisor PIN is required';

  @override
  String posc67d91cca2be(String arg1) {
    return 'PIN temporarily locked. Try again after $arg1.';
  }

  @override
  String get posafb55c20b67a => 'Invalid PIN';

  @override
  String pos696aa1b34ef8(String arg1) {
    return 'Could not update PO: $arg1';
  }

  @override
  String get pos33d25940f1a8 =>
      'PO is not approved and cannot be printed as an official document yet.';

  @override
  String pos4a59442df598(String arg1) {
    return 'PO page $arg1';
  }

  @override
  String get posa3c6a5810273 =>
      'PO can no longer receive goods. Check the latest status before creating a new request.';

  @override
  String pos62e8e1dd4504(String arg1) {
    return 'Could not check open POs: $arg1';
  }

  @override
  String get pos1f963bbc11d3 => 'A closed PO cannot receive more goods.';

  @override
  String get pos1bdb95acfb37 => 'PO not found';

  @override
  String pos5c04fa38f710(String arg1) {
    return 'PO: $arg1';
  }

  @override
  String get pos302161171b37 => 'POINT OF SALE';

  @override
  String get pos4abd3985ba80 => 'POS';

  @override
  String get pos4c43bce2f75e => 'POS & Inventory';

  @override
  String get pos7be1648ccde7 => 'POS / Retail';

  @override
  String posa8e0e5d00653(String arg1) {
    return 'POS Mobile ($arg1)';
  }

  @override
  String get pos2f59f12da563 => 'POS ready to use';

  @override
  String get posea28acda10e0 => 'VAT (%)';

  @override
  String posc53479dd68b9(String arg1) {
    return 'VAT ($arg1%)';
  }

  @override
  String get posf549f53f0f38 => 'PURCHASE ORDER';

  @override
  String get pos0ca6630f8da2 => 'Pairing failed.';

  @override
  String get pos7fe412d4db0e => 'Tax';

  @override
  String pos62e104d5b8c0(String arg1) {
    return 'Tax    $arg1';
  }

  @override
  String get pos3b7cc0983555 => 'Tax & Finance';

  @override
  String get pos1c019b5a318e => 'Tax (%)';

  @override
  String get pos5a2e9c877bbb => 'Tax must be between 0 and 100 percent';

  @override
  String get pos681bd4010b93 => 'Tax must be within 0–100%.';

  @override
  String get pos495f9bff5a0e => 'Transaction tax (%)';

  @override
  String get pos3c97ce060ce2 => 'Bundle';

  @override
  String get pos678240e33a4d => 'Bundle (component stock)';

  @override
  String get pos04611b81b2b4 =>
      'The trial plan activates automatically after the business profile is created.';

  @override
  String get pos738c87593325 => 'Force continue';

  @override
  String get posd427334c1222 =>
      'The interactive guide highlights product search, cart, customers, and fulfillment type.';

  @override
  String get pos2643f0cd5bdd =>
      'The cashier guide has been completed and POS is ready to use.';

  @override
  String get pos846f60a5b73d => 'Cashier transaction guide';

  @override
  String get pos03d6254f41fb => 'Monitor sales anytime';

  @override
  String get pos787caf16bfe3 => 'Monitor transactions';

  @override
  String get pos6b5dafc69e0a => 'Pantoo';

  @override
  String get pos01b2e69d6fa9 => 'Pantoo POS';

  @override
  String get pos8be3c943b160 => 'Password';

  @override
  String get pos211e672794db => 'Account password';

  @override
  String get posaaf0a22fd3ea => 'Password must be at least 8 characters';

  @override
  String get posdab355983303 => 'Password is required';

  @override
  String get poscbdd94221370 => 'Keep POS and Inventory aligned';

  @override
  String get pose4c906f412e4 => 'Check that the return details are correct.';

  @override
  String get posbc5c68313a8b =>
      'Ensure prices, stock, promotions, customer, and shift have been corrected. The server will recalculate and validate this transaction.';

  @override
  String get pos195cac54b1c7 =>
      'Ensure the sales location is active before linking it to a POS store.';

  @override
  String get posc1a3f392520f =>
      'Confirm payment has been received on the device or merchant account before processing. POS records the payment method and does not run an automatic payment gateway.';

  @override
  String get pos336fac8d52c6 =>
      'Ensure the product is active and visible in the sales catalog.';

  @override
  String get pos2eec238fa1ce =>
      'Ensure stock-tracked products use consistent locations and units.';

  @override
  String get pos7c54f7a9d9d7 => 'Check the document details before continuing.';

  @override
  String get pos468d2133243d =>
      'Ensure the shift is open at the store serving today\'s transactions.';

  @override
  String get posbcbef5a9f3fa => 'Local payload';

  @override
  String get pos544b8efc9443 => 'Workshop Jobs';

  @override
  String get pos7a95c90c9044 => 'Service-based jobs';

  @override
  String get pos5fc5f5280c54 =>
      'Learn to save active orders and proceed to payment and receipts.';

  @override
  String get posaf0ab4433946 => 'Customers';

  @override
  String get pos437a6e3cfda6 => 'Customer / Table';

  @override
  String get pos91cff7aeb01e => 'POS customer data unavailable';

  @override
  String get pos3a5a53b1566e => 'Transaction Customer';

  @override
  String get pose5141a6ccfac => 'Walk-in Customer';

  @override
  String get posee9ef7297ddc => 'Customer Selection Required';

  @override
  String get pos4899fcfdc5f6 => 'Customer deleted';

  @override
  String get pos727d3a540546 => 'Customer saved';

  @override
  String get pos6bf58e968c9b => 'Customer added';

  @override
  String get pos7643a04897af =>
      'Customer saved, but no customer ID was received';

  @override
  String get posb95f6d3181a8 => 'Customer not found';

  @override
  String get pos4866ef8a31f5 => 'Walk-in customer';

  @override
  String get pos467968fe0458 => 'Walk-in customer selected';

  @override
  String get pos77bfd66f8168 => 'A customer is required for this POS profile';

  @override
  String get posec4690a862aa =>
      'A customer is required for this fulfillment type';

  @override
  String get posa0218cf87673 => 'Customer: Walk-in Customer';

  @override
  String pose8576d8afa6c(String arg1) {
    return 'Customer: $arg1';
  }

  @override
  String pos0a36262b25f5(String arg1) {
    return 'Customer: $arg1\n';
  }

  @override
  String pos5f2c9e5e92b4(String arg1, String arg2) {
    return 'Usage: $arg1/$arg2';
  }

  @override
  String get pos73b0a9bc9815 =>
      'Cancellation reverses the stock movement back to its source. Ensure the destination or transit stock is sufficient.';

  @override
  String get pos3ac3498cb0dc => 'Could not cancel payment';

  @override
  String get pos462ab9a7ce8e =>
      'The previous cancellation is incomplete. Retry to finish the reversal journal entry.';

  @override
  String get posf0874594eb78 => 'Payment';

  @override
  String get posdeea40f5a356 => 'Payment Successful';

  @override
  String get poseeca4a051f2b => 'Payment Failed';

  @override
  String pos26eb6e9694bd(String arg1) {
    return 'PO payment $arg1';
  }

  @override
  String get poscfc71d335b86 => 'Insufficient Payment';

  @override
  String get pos1a292ae60985 => 'Payment successful!';

  @override
  String get pos5158591538d6 => 'Payment cancelled and journal entry reversed';

  @override
  String get posdff803622eaa =>
      'Payment accepted by the server, but local proof could not be updated. Reload before continuing.';

  @override
  String get pos71a0b91660a0 => 'Could not save payable payment';

  @override
  String get posd1faba7b4922 => 'This payment';

  @override
  String get pos3d560d6087d4 => 'Could not process invoice payment';

  @override
  String get posa95cbe825211 =>
      'Non-cash payments require server verification. Choose Cash or connect the device to the internet.';

  @override
  String get posc21910623c68 => 'Payment recorded';

  @override
  String get pos9a469f02f486 =>
      'Payment is available after the first receipt is recorded.';

  @override
  String get pos36b10f4c63f0 => 'Payment not found';

  @override
  String pos47ced915a77a(String arg1) {
    return 'Payment $arg1 will be reversed in the journal and restored as a payable.';
  }

  @override
  String pos0e93e26fcc3b(String arg1) {
    return 'Payment: $arg1';
  }

  @override
  String get pos40fb4ba95b58 => 'Buyer';

  @override
  String get posa266463e5684 => 'Purchases';

  @override
  String get pos7f58b58ae05a => 'Purchasing & Receiving';

  @override
  String get pos1349bbfde1db => 'Direct Purchase';

  @override
  String get posa6ecfd4c4da6 => 'PIN creation unavailable';

  @override
  String get pos348bbc8d9acb => 'Price Rounding';

  @override
  String get pos987bddc13363 => 'Invalid POS profile fulfillment';

  @override
  String pose6d93ee48cd5(String arg1) {
    return 'The requester wants to become a customer using number $arg1. Confirm, then select an existing profile or add a new customer.';
  }

  @override
  String get pos169ead46c156 => 'Service staff';

  @override
  String posa21c3b378169(String arg1, String arg2) {
    return 'Responsible party: $arg1 · Project: $arg2';
  }

  @override
  String get poscb23b0c42cec => 'PO printing cancelled or failed.';

  @override
  String get posc5bfc8ed9319 => 'Printing cancelled or failed.';

  @override
  String get pos5e19b1a72a86 => 'Label printing cancelled.';

  @override
  String get posa500f2871bbc => 'Registration Successful';

  @override
  String get pos44d976b9e0fa => 'Today\'s Revenue';

  @override
  String pos14401dca7861(String arg1) {
    return 'Revenue $arg1';
  }

  @override
  String get pos7efe502de734 =>
      'The actual placement must be in the transfer\'s destination warehouse.';

  @override
  String get posbd870ab7ab13 => 'Receiving';

  @override
  String get pos750232066a15 => 'Goods Receipt';

  @override
  String get pos7509362285bd => 'Cash Receipts';

  @override
  String get pos8b1fc3d1fa70 => 'Goods receiving';

  @override
  String get pos59dc4a661597 => 'Receipt cancelled';

  @override
  String get pos47db2ea96b3d => 'Receipt from supplier';

  @override
  String get pos9ad658342acf =>
      'Could not receive transfer. Reload to check its status.';

  @override
  String get pos8ed81389e32e =>
      'Partial receipts are supported. Enter only the quantity arriving now; the remainder can be received later.';

  @override
  String get pos72c698870099 => 'Recorded partial receipts';

  @override
  String get pose0963221e1a9 => 'Purchase receipt recorded';

  @override
  String get posa609bf18a1d0 => 'Partial receipt recorded';

  @override
  String get pos04bc1b7c365e =>
      'The previous receipt is already recorded; the request was not resent.';

  @override
  String get posb6c6364e3add =>
      'Receipt recorded in Finance. Stock is unchanged.';

  @override
  String get pos05f9c28311c7 => 'Receipt recorded; remainder stays in transit';

  @override
  String get pos2b4ff2a4ed85 =>
      'Intake, laundry processing, pickup, and delivery';

  @override
  String get pos9adf173776ee => 'Delivery';

  @override
  String get pos3fcdc1c4886d => 'Settings';

  @override
  String get posc2a1a7bc8f01 => 'Print Settings';

  @override
  String get posa6e412670477 => 'QR Print Settings';

  @override
  String get pos4abb25f8759e => 'QR Code Print Settings';

  @override
  String get pos8e7869583112 => 'Vehicle Settings';

  @override
  String get posad02c326569e => 'PIN settings updated';

  @override
  String get posf78996a42a51 => 'Could not process PIN settings';

  @override
  String get pose448f6706003 => 'POS Settings';

  @override
  String get pos5fc77a1fa51e => 'Printer Settings';

  @override
  String get pos7bbfda48ddc4 => 'Receipt Settings';

  @override
  String get posff057d419bee => 'Settings saved';

  @override
  String get pos1d50f6761638 =>
      'These settings apply as POS operating defaults.';

  @override
  String get pos041be20d76d2 =>
      'Settings are saved to the database and shared with POS Admin and Inventory.';

  @override
  String get posb51af5a191e0 =>
      'Could not load customer settings. Try again when connected.';

  @override
  String get pos003d670b7cbd => 'Could not load customer settings. Try again.';

  @override
  String get posb06ae32ef97e => 'Receipt settings saved';

  @override
  String get posafd542ed86f2 => 'Could not load receipt settings';

  @override
  String get posc720f7612f49 => 'Users';

  @override
  String get pos87594ba2bb9c => 'User not found in this organization';

  @override
  String get posf5064fda288a => 'Delivery';

  @override
  String get posd330ba42196d => 'Delivery from outlet';

  @override
  String get pos20dd92d09621 =>
      'Dispatching to transit: destination stock increases only after receiving.';

  @override
  String get posf577b29c51a3 => 'Sales';

  @override
  String get pos3b91e2010d2b => 'Expired Item Sales';

  @override
  String get pos1cbe1294fd2c => 'Deposit Sales';

  @override
  String get pos063da5c806a2 => 'Today\'s Sales';

  @override
  String get pos188eb84be3dd =>
      'Sales without a shift are permitted by POS policy.';

  @override
  String pos063e03843503(String arg1) {
    return 'Sales for the Last $arg1';
  }

  @override
  String get posd7fc0ffb0ed7 => 'Resolution';

  @override
  String get pos50b47d38dfab => 'Discrepancy resolution';

  @override
  String pos57915034b172(String arg1) {
    return 'Resolution: $arg1';
  }

  @override
  String get pos6be6f1877afe => 'Handover';

  @override
  String get pos636321469856 =>
      'PIN storage unavailable. Online verification required.';

  @override
  String get pos74a586d6b8f9 => 'Browser storage rejected order data';

  @override
  String get pos3887933a52b5 => 'Device rejected request storage';

  @override
  String get pos6e9a2f805880 =>
      'Other offline devices cannot be detected. Ensure every cashier on this shift has synced and physical cash has been reconciled.';

  @override
  String get pos851e8c6bca8b =>
      'Device offline. Cash sales are saved locally and waiting to sync.';

  @override
  String get pos4e197bd5a06d => 'Device is offline';

  @override
  String get posb8a45c361d38 =>
      'Device offline. This operator has no local PIN cache; connect once for initial verification.';

  @override
  String get posb2bf5d7b9022 =>
      'Device offline. Previously authenticated sessions open automatically; first sign-in or signing in after logout requires internet.';

  @override
  String get pos3a5ec7f46fc1 => 'Correct Purchase Return';

  @override
  String get posc1fa4d0e39e4 =>
      'Update document details and stock count results.';

  @override
  String get pos11163811c0bd => 'Update status';

  @override
  String pos7d60a10a7702(String arg1) {
    return 'Sync attempts: $arg1';
  }

  @override
  String pos919294430196(String arg1) {
    return 'Attempts: $arg1';
  }

  @override
  String get pos15fde549f970 => 'Cashier Performance';

  @override
  String get posd1c4bf867dc6 => 'Review';

  @override
  String get pose4f82cb96e1d => 'Review & decide discrepancy';

  @override
  String get pos5cba9de4623c => 'Review Again';

  @override
  String get posb40a738a07a4 => 'Check History';

  @override
  String get pos909e2d8b157e => 'Check first';

  @override
  String get pos888b973df441 => 'Check prices';

  @override
  String get pos7495cad8f33b =>
      'Check quantity, purchase price, and discount for each item';

  @override
  String get pos0334dacff8fa => 'Check again';

  @override
  String get pos3c5de457478d => 'Recheck shift';

  @override
  String get posd3742633c646 =>
      'First check whether the invoice is already on the server. Ensure received money has been returned or reconciled. The transaction trail remains on the device.';

  @override
  String get pos7a9db5794ed8 =>
      'First check whether the order is already on the server. If not, the local order can be resolved after informing the customer. Its trail remains on the device.';

  @override
  String get pos0fefa3ec8de5 => 'Check settings';

  @override
  String get pose54d897562ee => 'Check other cashier devices';

  @override
  String get pos6b9246966cac => 'Check transaction profile';

  @override
  String get posde9c5e3dcdb6 => 'Check store status';

  @override
  String get pos7b21414952b5 =>
      'Check the active store and open a cashier shift before creating orders.';

  @override
  String get pos51c207011a12 => 'Check server transaction';

  @override
  String get pos78659c9a6100 => 'Minimum stock alert';

  @override
  String get pos85e181b57a56 => 'Period';

  @override
  String get pos7559a88f2a3e => 'Estimated funding needs';

  @override
  String get pos7af907a24b5b => 'Cost treatment';

  @override
  String get poscc925cc7522e => 'Stocktake access required';

  @override
  String get pos1c9ed065a9c8 => 'Setup required';

  @override
  String get pos67c4b57f25d3 => 'Needs review';

  @override
  String get pos166e0b446d19 => 'Approval required';

  @override
  String get pos39154964c2c8 => 'Needs my action';

  @override
  String posa67275acc90a(String arg1) {
    return 'Expand $arg1';
  }

  @override
  String get pos21b92e2945e7 => 'Down Payment Request';

  @override
  String get posa2f3b4d3283e => 'Could not save down payment request';

  @override
  String get pos1bb95bff678f =>
      'Down payment request sent. Awaiting Finance approval and payment.';

  @override
  String get pos87c742af3515 =>
      'This request does not disburse money. Finance must still approve and pay separately.';

  @override
  String get pos3b6a51e586af => 'Customer profile request';

  @override
  String get posb41fc25c6a52 =>
      'The last request is unconfirmed. Saved quantities and locations will be resent; current form changes will not be included.';

  @override
  String get posa5a4b853cf69 =>
      'Request saved. Awaiting approval; cash has not been deducted.';

  @override
  String get pos871d16a76eb4 => 'Supplier advance request';

  @override
  String get posde08bb634a50 => 'Percent';

  @override
  String get pos3778aa59db1d => 'Percentage (%)';

  @override
  String get pos5fc71f538952 => 'Consent is required to create an account.';

  @override
  String get pos61ff1cf7478e =>
      'Approving a loss requires scrap approval permission. You may reject the report.';

  @override
  String posb11d7ad2d4ac(String arg1) {
    return 'Approval $arg1 • rules locked after submission';
  }

  @override
  String pos3b0f37c81a64(String arg1, String arg2) {
    return 'Approval $arg1/$arg2';
  }

  @override
  String get pos40f073237966 => 'Personal';

  @override
  String get posf506ccdb8e76 => 'Revenue Growth';

  @override
  String get pos62d1855e8263 => 'Transaction Growth';

  @override
  String get posa20d6217eda2 => 'Changes cancelled.';

  @override
  String get pos059e6f7883d7 => 'Could not process order changes';

  @override
  String get pos412dd953969a => 'Change recorded as a transaction override';

  @override
  String get pos2d4162712448 => 'Delivery';

  @override
  String get posdbefd5b08844 => 'Delivery';

  @override
  String pos0bff6b4c25ac(String arg1, String arg2, String arg3) {
    return 'Message from $arg1 at $arg2: $arg3';
  }

  @override
  String get pos371a2a377534 => 'Order from supplier';

  @override
  String get pose88ee63879a9 => 'Reorder';

  @override
  String get posaf947234cc1b => 'Orders';

  @override
  String get posd0658219f7c4 => 'Orders & Tables';

  @override
  String get posa496c99bbf7b => 'Active Orders';

  @override
  String get pos41b6ba1b6db4 => 'Active Orders & Tables';

  @override
  String get pos773636fad145 => 'New Order';

  @override
  String get pos0a2e2a094314 => 'Laundry Orders';

  @override
  String get pose6e1e3329ff4 => 'Service Orders';

  @override
  String posf86f87a78d52(String arg1) {
    return 'Table $arg1 Order';
  }

  @override
  String get pos0a35cb3e503b =>
      'QR orders are processed after payment at the cashier';

  @override
  String pos3b458bf929ac(String arg1) {
    return 'The order will be recorded at table $arg1. The table is marked occupied and its bill can be resumed from Active Orders & Tables.';
  }

  @override
  String get posb2b2fef5a283 => 'Active orders';

  @override
  String get posd2999deece68 => 'Could not save the order on this device';

  @override
  String get pos8e28bf2b73d3 => 'Order updated';

  @override
  String get posa9c01eb5f898 =>
      'Orders containing \"Send to kitchen\" products appear here. Ready-made products do not enter the queue.';

  @override
  String get posa27a48a65cba => 'Order cancelled';

  @override
  String get pos1591c15f679c => 'Order held temporarily';

  @override
  String get posdf79967b4ba9 =>
      'Existing orders retain their snapshot. The new profile applies to future transactions. Recheck tables, services, customers, and fulfillment types.';

  @override
  String pos6fe4c911e4d5(String arg1) {
    return 'Order for table $arg1 saved.';
  }

  @override
  String get pos53fd557c7923 =>
      'Offline order saved. Not yet sent to tables/kitchen; check Queue & Sync.';

  @override
  String get pos93e538d96629 =>
      'Operational orders are saved for preparation and later payment, not as Finance receivable invoices. Open them from Orders or Transaction History; use Save order for a temporary cart.';

  @override
  String get posac7404519b39 => 'Order already on the server';

  @override
  String get pos74ecaa1b9f86 => 'Newest orders';

  @override
  String get posebe8c57f5cb4 => 'Oldest orders';

  @override
  String get pos352c6cc8bd8e => 'Saved orders';

  @override
  String get pos03ecfa106dbe => 'Order cannot be cancelled';

  @override
  String get pos4a7b1648aafd =>
      'Completed orders are available in Transaction History.';

  @override
  String pose27a8b678805(String arg1) {
    return 'Order $arg1';
  }

  @override
  String posbe4e656f20d1(String arg1) {
    return 'Order $arg1 is unpaid. Reserved stock will be released.';
  }

  @override
  String posc8b050cf8ef3(String arg1) {
    return 'Order $arg1 updated.';
  }

  @override
  String posf970ac5a216e(String arg1) {
    return 'Order $arg1 is available in Orders and Transaction History.';
  }

  @override
  String posbf7cbf6e7df0(String arg1, String arg2) {
    return 'Order $arg1 saved at table $arg2.';
  }

  @override
  String get posedaf7adb17af => 'Table Map';

  @override
  String get pose137919915b5 => 'Select';

  @override
  String get pos4961e3a50c3b => 'Select Items to Return:';

  @override
  String get posb587a0f7dba2 => 'Select Cashier';

  @override
  String get pos52def59984f8 => 'Select a PO and stock location first';

  @override
  String get pos099ac28689df =>
      'Select a PO with a remaining down payment agreement';

  @override
  String get pos320d17578301 => 'Select Customer';

  @override
  String get posfdd613a427ae => 'Choose WhatsApp or another app';

  @override
  String get posbd006c5b464a => 'Select a correction reason';

  @override
  String get pos4ad6b1404620 => 'Select items';

  @override
  String get pos709fdf8ae6e9 => 'Select a valid item and location balance.';

  @override
  String get pos5dfffa7a1318 =>
      'Select items from location stock to start filling the table.';

  @override
  String get pos65516be18338 => 'Select PO line';

  @override
  String get posfa0626bb42ca => 'Select batch';

  @override
  String get pos24f3a034b35c => 'Select transfer batch';

  @override
  String pos9518606db839(String arg1) {
    return 'Select batch $arg1';
  }

  @override
  String get pos0f6c6fedcedf =>
      'Select the correct branch through rack so opening stock is recorded at its physical location.';

  @override
  String get poscb0fcc1c4066 => 'Select a receiving branch before scanning.';

  @override
  String get pos77888323ec06 => 'Choose photo';

  @override
  String get pos80f5a8d955cf =>
      'Select the location\'s primary function, such as store or central warehouse.';

  @override
  String get pos06b8038867a2 => 'Choose image';

  @override
  String get pos4638e00a2067 => 'Select warehouse';

  @override
  String pos28da64abd533(String arg1) {
    return 'Choose the most important information for $arg1 operations.';
  }

  @override
  String get posf86f4256c556 => 'Select invoice and items';

  @override
  String get posd5df0db008e7 => 'Select service schedule';

  @override
  String get pos6be9415d49a2 => 'Select product type';

  @override
  String get posf5c237c88c94 => 'Select employee';

  @override
  String get pos60a99b71af5d => 'Select an employee first';

  @override
  String get posc71c04e0152f =>
      'Select the employee who will use the POS cashier.';

  @override
  String get pos5322c62fbfeb => 'Select category';

  @override
  String get pos18bc245517d2 =>
      'Select a category for faster catalog searches and filtering. Add categories using the + button.';

  @override
  String get posea08738178f6 => 'Select bundle components';

  @override
  String get pos35dd55e65eb1 => 'Select stock component *';

  @override
  String get posf59f9e84c6a6 => 'Select order context';

  @override
  String get pos0896a043009e => 'Select a source location first';

  @override
  String get pos39c964d26616 => 'Select source and destination locations.';

  @override
  String get pos77845316790e =>
      'Select a location and enter the received quantity';

  @override
  String get pos47dd0da5a204 => 'Select a rack restocking location';

  @override
  String get posaa5cbc57913b =>
      'Select a quarantine location for damaged goods.';

  @override
  String get pos907d106c0c78 => 'Select balance location';

  @override
  String get poseea7cef26cbc => 'Select PO receiving stock location';

  @override
  String get pos21084f943554 => 'Select source location';

  @override
  String get posac33e5d3b94e => 'Select a store location to load the catalog';

  @override
  String get pos806e3503c247 => 'Select a different destination location';

  @override
  String get pos08be59662c42 =>
      'Select the location to count. Its balance will be snapshotted automatically.';

  @override
  String get pos3f55fbdf2353 =>
      'Select a table from the fulfillment type menu first.';

  @override
  String get pos06ec9d461857 => 'Select a table from the cashier page first.';

  @override
  String get pose626124c671a => 'Select a table for the order';

  @override
  String get pos8c28e3c0f8c4 =>
      'Choose payment method, split payment, notes, and invoice if needed.';

  @override
  String get pos4a9eb2ac0a2e => 'Select at least 1 item to return';

  @override
  String get pos4ef6120aadb2 =>
      'Select at least one item and enter the return quantity';

  @override
  String get pos33883a3bf54e =>
      'Select actual serial numbers, one per unit, from the transfer remainder.';

  @override
  String get posd840f8f1ce4b => 'Select operator';

  @override
  String get posdd3bb4425063 =>
      'Select an operator and create/enter the cashier PIN.';

  @override
  String get pos683fb000ce5c => 'Select an operator and enter a 4–6 digit PIN';

  @override
  String get pos83d9841efcfb =>
      'Select an operator and enter the PIN to continue';

  @override
  String get pos3f02d5042e1b => 'Select cashier operator';

  @override
  String get pos83ac49b96164 => 'Select customer';

  @override
  String get pose0ea931f61de => 'Select a customer first for credit sales.';

  @override
  String get pos70585fecd75e =>
      'Select a customer for points, promotions, and purchase history';

  @override
  String get pos7a5d67b6c307 => 'Select purchase and return location';

  @override
  String get posf3e599685a4f => 'Select dashboard period';

  @override
  String get pos72c35021a5ae =>
      'Select a Bluetooth printer in Printer Settings first.';

  @override
  String get pos7cd2a2d08d87 =>
      'Select a printer in Terminal Printer Settings.';

  @override
  String get pos97d0edd1cd6f => 'Select business profile';

  @override
  String get pos5da93a6249f6 => 'Select the rack being counted';

  @override
  String get pos5a6498c8f0a9 => 'Select a bank account for the transfer.';

  @override
  String get pos5b05aca5d8d4 => 'Select an account for transfer cost payment.';

  @override
  String get posf0a1bc36d652 => 'Select location balance *';

  @override
  String get pos089a0f4fc2f2 =>
      'Select the correct physical location balance. Corrections are for technical entry errors or migration only; physical counts are processed through Stocktake.';

  @override
  String get pos148cad088f6c => 'Select base unit';

  @override
  String get posf8c1cdf075c0 =>
      'Select the smallest stock unit, such as pcs, servings, or bottles. Packaging conversions can be added below.';

  @override
  String get posb19d2b4f4201 => 'Select the production station for this item';

  @override
  String get pos99f1f5366c28 => 'Select stock source';

  @override
  String get pos97a1701e1552 => 'Select supplier';

  @override
  String get posac0270f821d1 => 'Select a supplier to continue';

  @override
  String get pos69774aafa14f => 'Select date';

  @override
  String get pos417e732e9cfc => 'Select date & time';

  @override
  String get posd3fd7fe483f5 => 'Select the installment to pay.';

  @override
  String get pos918a38df1fbe => 'Select warehouse type';

  @override
  String get pos0822b1ae9504 => 'Select cashier store';

  @override
  String get pos69d036b4ed5e => 'Select operating store';

  @override
  String get pos43a2717b8f48 => 'Select a store to load the kitchen queue';

  @override
  String get pos2ae8df888b0e =>
      'Select a store, enter opening cash, then open the shift.';

  @override
  String get pos551888c64850 =>
      'Select a warehouse marked as a sales location for store stock.';

  @override
  String get pos5de4f71b3421 =>
      'Select an active warehouse/sales location for store stock.';

  @override
  String pos42aa2abf5ad3(String arg1) {
    return 'Select $arg1';
  }

  @override
  String get pos34ada2e93f20 => 'Split Payment';

  @override
  String get posa3fd3d4be631 => 'Receivables & Settlement';

  @override
  String pos1d6fd1683a30(String arg1, String arg2, String arg3) {
    return 'Receivables reduced $arg1 · Refund $arg2 · Credit balance $arg3';
  }

  @override
  String get posed3d014a4485 =>
      'Receivables are only available to operators with Finance permission.';

  @override
  String get posa76456858256 => 'Receivables · manage in Finance';

  @override
  String get posa1539fde74fa =>
      'Cashier placeholder: {{nama_kasir}}  (alias: {{kasir}}). Example: Served by {{nama_kasir}}';

  @override
  String get posb51c5e7468f6 =>
      'The POS phone and customer display must share the same private Wi-Fi/hotspot. This mode does not require internet; keep the POS app open. Avoid public Wi-Fi.';

  @override
  String get posb55223c7bdc7 => 'Portal';

  @override
  String get posa1670bdfd674 => 'Additional discount between 0–100%';

  @override
  String get posec2630527c8b => 'Portrait';

  @override
  String get posaefb2c722166 => 'Preview / Share';

  @override
  String get pos8fb4d431e5f5 => 'Preview PO';

  @override
  String get posa0517112362a => 'Preview labels';

  @override
  String get posbf8e8e197f4d => 'Invoice Prefix';

  @override
  String get pos85d88da6d103 =>
      'Invoice prefix must contain 1–10 letters or numbers.';

  @override
  String get posdd8c6beb8f62 => 'Precise (PDF + logo)';

  @override
  String get pos4bc8972ab9b3 => 'Receipt Preview';

  @override
  String get pos280ef1d0199d =>
      'The preview updates live with the settings on the left.';

  @override
  String get posb9e296f62897 => 'Price preview unavailable';

  @override
  String get pos4c6aae8435a6 => 'Print Invoice';

  @override
  String get pos8603bde055dd => 'Print Receipt';

  @override
  String get posf161eb61452f => 'Bluetooth printer selected';

  @override
  String get posd1c6d22c93dc =>
      'The cashier Bluetooth printer is saved on this device for receipts and thermal labels. A4 POs and payment proofs use the device print dialog to select a printer.';

  @override
  String get pos591a9e65d14b => 'Bluetooth printer rejected receipt data';

  @override
  String get pos7daf17b7f7b4 => 'Bluetooth thermal printer';

  @override
  String get pos649513b7074a =>
      'Bluetooth printer not responding. Check its connection.';

  @override
  String get posefc8c22a5026 => 'This Terminal\'s Printer';

  @override
  String get posaf57377b32ae => 'Select a printer from Printer Settings';

  @override
  String get posac376db4a4bc => 'Terminal default printer';

  @override
  String get posa30a2081e4f7 => 'Printer rejected some labels.';

  @override
  String get pos8b336c0163c2 =>
      'Printer response timed out. Check the connection and retry.';

  @override
  String get posd7e27376368f =>
      'Saved terminal printer unavailable. Select it again in Printer Settings.';

  @override
  String get posd0c9b622f84f =>
      'Printer not responding. Check its connection or driver.';

  @override
  String get pos51920b6b7ae9 => 'Printer not responding. Check its connection.';

  @override
  String get pos51cb5d20e6cb => 'Priority';

  @override
  String get pos13da982ef4aa => 'Privacy and security you can trust';

  @override
  String get pos869eb84eb3dc => 'Products';

  @override
  String get pos1138b2d9becd => 'Sample Product A';

  @override
  String get posdda7c4cb3ebf => 'Sample Product B';

  @override
  String get pos8f9d458d26c3 => 'Expired Products';

  @override
  String get pose1afb631b23e => 'Service Products';

  @override
  String get pos0da22a551588 => 'Bundle Products';

  @override
  String get pos1e32a5808bac => 'Products Sold';

  @override
  String get posa357bd367628 => 'Best Sellers';

  @override
  String get pos06fb51535ff5 =>
      'New products start with 0 stock. Record opening balances or stock changes through Store Stock to keep locations and stock history valid.';

  @override
  String get posb6483575f031 => 'This product has no code for labels.';

  @override
  String get posf640370cc858 =>
      'This product has no balance in this warehouse. Add stock through receiving or transfers first; stocktake requires a recorded location balance.';

  @override
  String get pos2a2a10ed9820 =>
      'Product is not saved for offline transactions.';

  @override
  String get posccb7fe69cbf8 => 'Product created';

  @override
  String get posde1096477c33 => 'Product deleted';

  @override
  String get pos09706678ca5b => 'Product updated';

  @override
  String get posc7bb9c341c76 => 'Next product';

  @override
  String get posec2438d3dbfa => 'Physical product (own stock)';

  @override
  String get posbb232b1b62e4 =>
      'This product is batch-tracked. Correct stock through Stocktake to keep batches and expiry dates consistent.';

  @override
  String get posaa41b88f9177 =>
      'This product is not in the remaining PO items.';

  @override
  String get pos54eb2930473e => 'This product does not use stock balances.';

  @override
  String get poscb5467abcdfe => 'Previous product';

  @override
  String get pos0bc283dc5c7a => 'Best sellers';

  @override
  String get pos0026bfce12f2 => 'Server did not return the product';

  @override
  String get posd71d5f161e97 => 'Products, barcodes, and store stock';

  @override
  String get pos543bbb66f3f5 => 'POS Business Profile';

  @override
  String get pos5d63d006cbcf => 'Inventory Profile';

  @override
  String get pos4b8a8b28136c =>
      'Inventory Simple profiles only receive stock at the default location';

  @override
  String get pos7674f2e0ef8c => 'Duplicate POS profile';

  @override
  String get pos9e0fb3d65a6f =>
      'This POS profile does not track stock. Enable Stock Tracking in POS Settings if products should be deducted during sales.';

  @override
  String get posdd3f53ab7f71 => 'Invalid POS profile';

  @override
  String get pos22cb048be681 => 'User Profile';

  @override
  String get pos6480b1d46dcd =>
      'This profile or fulfillment type requires a customer.';

  @override
  String get posb03276b31a5d =>
      'Business profile or Stock Tracking cannot be changed';

  @override
  String get posb25c367c89a2 =>
      'This profile is the main workspace for your store or organization, products, cashiers, reports, and Pantoo trial.';

  @override
  String get posb154f59af7cf =>
      'Inventory profile and POS stock rules are consistent.';

  @override
  String pos647182c03196(String arg1) {
    return 'Inventory profile: $arg1. Stock, purchases, stocktake, transfers, waste, and returns are available according to account permissions.';
  }

  @override
  String get pose713185ec3fa => 'Profile is still used in operations';

  @override
  String get pos87960d620984 => 'Business profile';

  @override
  String get posab57b24264e8 => 'Could not create business profile';

  @override
  String get pos741cc223e0db =>
      'Operational features follow your business profile. Customize them later in POS Settings → Transactions & Sales.';

  @override
  String get pos0c14cf63b0e8 =>
      'Pro forma attached · supporting proof only, not a Vendor Bill';

  @override
  String pos7dfa2cce27c1(String arg1) {
    return 'Pro forma: $arg1';
  }

  @override
  String get pose0f4f87da3de => 'Promo';

  @override
  String pos5f0e590eb67a(String arg1) {
    return 'Promotion    -$arg1';
  }

  @override
  String pos33d2c3ae1407(String arg1) {
    return 'Promotion \"$arg1\" created';
  }

  @override
  String posf923a5377f98(String arg1) {
    return 'Promotion \"$arg1\" updated';
  }

  @override
  String pos2a3d9ec5d50a(String arg1, String arg2) {
    return 'Promotion \"$arg1\" successfully $arg2';
  }

  @override
  String get pos6222e034ade4 => 'Promotions & Discounts';

  @override
  String get posbf5882aa45e5 => 'Promotions & Vouchers';

  @override
  String get pos11b0997ad729 => 'Promotion requirements not met';

  @override
  String get pos236d5e96ed6f => 'Promotion deleted';

  @override
  String get pos12ea083e3644 => 'Promotion applied';

  @override
  String get pos891fa7bb20d2 => 'Promotion only';

  @override
  String get pos58df4233fa45 =>
      'Promotions, discounts, taxes, and fees are summarized before payment.';

  @override
  String get pos2023525f33bb => 'Process';

  @override
  String get pos04f0bc1ae070 => 'Process Payment';

  @override
  String get pos5628f88ed746 => 'Process Payment';

  @override
  String get pos5d7671ae674d => 'Process Invoice Payment';

  @override
  String get pos16b3eaa5db4f => 'Process Return';

  @override
  String get pos842b4aa99f70 => 'Process Stock';

  @override
  String get poscafa9231b673 => 'Process service';

  @override
  String get pos3058d0885078 => 'Process payment';

  @override
  String get posbd31d165b7b4 => 'Seamless payment processing';

  @override
  String get pos974113ed5333 => 'Process return?';

  @override
  String get pos06f4807d49e0 => 'Reprocess';

  @override
  String get pos1c9c05321ac4 => 'Project';

  @override
  String get pos4dc41ac187b4 => 'Restore the unconfirmed return draft first.';

  @override
  String posc4171a22051c(String arg1) {
    return 'Restore proof $arg1';
  }

  @override
  String get posb03c898f4c0d => 'Restore return draft';

  @override
  String get pos3c45b957fdc8 => 'Purchase Order';

  @override
  String get pos9ac7b79547ea => 'Selected Purchase Order';

  @override
  String get pos3b45046321f9 => 'Disconnect';

  @override
  String get pos16dcfba0340a => 'Pantoo POS Table QR';

  @override
  String get pose4e6da0b48b9 =>
      'This QR code is permanent. Monitor Web Orders before staff start preparing them.';

  @override
  String pos133f8123ec8d(String arg1) {
    return 'Table QR $arg1';
  }

  @override
  String pos8c5a30764897(String arg1) {
    return 'QR $arg1';
  }

  @override
  String get posa8d6682e6a6a => 'QRIS';

  @override
  String get pos1e5ff9e500c2 => 'Qty';

  @override
  String posbc47f5da0ae0(String arg1, String arg2) {
    return 'Original Qty: $arg1 $arg2';
  }

  @override
  String get pose7b155797eb0 => 'Return Qty';

  @override
  String get pos8f6e9ad919a6 => 'Quality Control';

  @override
  String get posf89332db8409 => 'Rack';

  @override
  String get posd796fab4ace6 => 'Rack (optional)';

  @override
  String posad54407447b0(String arg1) {
    return 'Rack $arg1';
  }

  @override
  String pos1af981c59b08(String arg1) {
    return 'Rack: $arg1';
  }

  @override
  String get pos482902c46d65 => 'Average / Transaction';

  @override
  String get pos36db4b26bf84 => 'Average Order';

  @override
  String get poscc63552558f8 => 'Real-time';

  @override
  String get pos6243755d7b5b => 'Partially recycled';

  @override
  String posc4042d7f65c7(String arg1) {
    return 'Recycled $arg1 • ';
  }

  @override
  String get pos3166201d7baf => 'Reference';

  @override
  String get posc65dccdd3292 => 'Reference / ticket (optional)';

  @override
  String get pos76d2d1517764 => 'PO reference unavailable. Reload the list.';

  @override
  String get pos94751b2cc725 => 'Could not load references. Try again.';

  @override
  String get pos5f95d9a50b17 => 'Payment reference (optional)';

  @override
  String get posaffaa9974a71 => 'Transfer reference';

  @override
  String get pos7de25f0023d9 =>
      'Reference for Finance; does not create a payable or payment.';

  @override
  String pos96b044b6e7c2(String arg1) {
    return 'Reference: $arg1';
  }

  @override
  String posea21c3d7a950(String arg1) {
    return 'Reference: $arg1\n';
  }

  @override
  String get pos56e3badc4e6c => 'Refresh';

  @override
  String get pos7d773b881b3c =>
      'Refunds and stock movements will follow the return details.';

  @override
  String get pos15b8b44ee8cf => 'Cash refund';

  @override
  String get posf993cffba741 => 'Shared register';

  @override
  String get posb97465b4316b =>
      'Shared register: one drawer per store for authorized accounts. Per operator: each PIN is reconciled separately.';

  @override
  String get pos60c4ba76c7de => 'Account';

  @override
  String get pos280fa8bb05b9 => 'Bank account';

  @override
  String get posd1bc54bee535 => 'Bank account *';

  @override
  String get pos79a9b4e67d92 =>
      'Could not load bank accounts. Cash or bank draft payments remain available.';

  @override
  String get pos036967f2c2dd => 'Cost payment account';

  @override
  String posd88b4d30bc43(String arg1) {
    return 'Account: $arg1';
  }

  @override
  String get pos8c9039befce5 =>
      'Reconcile cash and close the shift when work is complete.';

  @override
  String get pos12cc792f0fdc => 'Current plan';

  @override
  String get posb97f4712bde6 => 'Plan only; Finance handles payment';

  @override
  String get pos0611cb3543b6 => 'Invalid time range or guest count';

  @override
  String get pos4062aae419d1 => 'Reorder Alert & Cost Price';

  @override
  String pos72f4ddb26760(String arg1) {
    return 'API request failed (HTTP $arg1) without an error message.';
  }

  @override
  String posbcd5593f5bcc(String arg1) {
    return 'Request not sent because it could not be saved on the device: $arg1';
  }

  @override
  String pos849ad4d3801b(String arg1) {
    return 'Request failed (HTTP $arg1)';
  }

  @override
  String get posd50df1e81ef3 =>
      'The previous request uses a location not allowed by the Simple profile. Re-enter receiving quantities at the default location.';

  @override
  String get pos519c54ce138a =>
      'The previous receiving request on this device cannot be read. New receiving is blocked to prevent duplicate stock. Check GRN history and contact an inventory administrator.';

  @override
  String get pos25d0e3d3a07d =>
      'The previous receiving request cannot be read. Check GRN history and contact an administrator before receiving again.';

  @override
  String get posa259ac911046 => 'Reseller';

  @override
  String get posb45dd3aea462 =>
      'Recipe/bundle data is unavailable for offline transactions. Connect to the server.';

  @override
  String get pos9cc2cf871dfe => 'Reservations';

  @override
  String get pos69d163afa2ee => 'Reservations & Services';

  @override
  String get posa077a8f388a3 => 'Reservations and customer services';

  @override
  String pos039cdeadaabb(String arg1) {
    return 'Reservation · $arg1';
  }

  @override
  String get pos44c57abd888a => 'Reset';

  @override
  String get pos0487356165fa => 'Reset to profile defaults';

  @override
  String get posa843c895becf => 'Invalid PIN settings response';

  @override
  String pos48c3ba336d52(String arg1) {
    return 'Server response: $arg1';
  }

  @override
  String get posc48f8c0f5f2d => 'Supplier response';

  @override
  String get pos9a536089f3ed => 'Supplier response recorded';

  @override
  String get pos023feb541ab2 =>
      'Response interrupted. Do not collect payment twice; use Resubmit the same proof.';

  @override
  String get posdd4c968c4616 =>
      'Empty transfer response. Reload before continuing.';

  @override
  String get pos64aa97a812fe => 'Invalid proof upload response';

  @override
  String get pos4a5c80fa526d => 'Invalid pro forma upload response';

  @override
  String get pos5b52143dd801 => 'Restaurant / Cafe';

  @override
  String get pos812d0896ea60 => 'Restaurant / Cafe';

  @override
  String get pos925dd33f9082 => 'Retail';

  @override
  String get pos5cfbc75b4208 => 'Retail / Store';

  @override
  String posb17d3b472148(String arg1) {
    return 'Automatic retry: $arg1';
  }

  @override
  String get pos7a82f9e98c12 => 'Returns';

  @override
  String get pos0e241374b8c6 => 'Purchase Returns';

  @override
  String get pos64bfb532598f => 'Sales Returns';

  @override
  String get pos8a44f03ed038 => 'Return will be saved as a draft';

  @override
  String get pos299b53317e1d => 'Return deleted';

  @override
  String get poscb804c0ee887 =>
      'Submitted sales returns and refunds appear here.';

  @override
  String get posff9563c75acd => 'Return created and submitted for approval';

  @override
  String get pos4a880b9a2380 =>
      'Return accepted but local proof is not updated. Restore it before creating another return.';

  @override
  String get pos2d5779ea48b8 => 'Return to Supplier';

  @override
  String get pos883e50798514 =>
      'Returns reduce receivables first. Only the already-paid difference is refunded. Cash uses account 1001; transfers use bank account 1002 in Finance.';

  @override
  String get pos999602d184e3 =>
      'Return confirmed. Check its status in the list; submission and refund remain separate.';

  @override
  String pos27df11542691(String arg1) {
    return 'Return $arg1 will await supervisor approval.';
  }

  @override
  String pos45799a85e9a2(String arg1) {
    return 'Return $arg1 will be ready to process.';
  }

  @override
  String pos8e1dc55435c2(String arg1) {
    return 'Could not load location details: $arg1';
  }

  @override
  String get pos17b252650858 => 'Balance details by location';

  @override
  String get posbaaf73d00305 => 'Compact sidebar';

  @override
  String get posd28feba12163 => 'Overview';

  @override
  String get pos26537d1df4a7 => 'Sales Summary';

  @override
  String get posdd37fa0a60b0 => 'Your shopping summary';

  @override
  String get pos8076ee30b32a => 'Purchase summary';

  @override
  String get pos75e583d10204 => 'Sales summary';

  @override
  String pos29a28ea5e03e(String arg1) {
    return 'POS performance summary for $arg1.';
  }

  @override
  String get posbdeacd1760b4 => 'History';

  @override
  String pos065a9e21d49d(String arg1) {
    return 'Could not update GRN history: $arg1';
  }

  @override
  String get pos611fe79e900e => 'Shift History';

  @override
  String get pos5906e6282ccf => 'Active Shift Stock History';

  @override
  String get pos8806dc3915aa => 'Transaction History';

  @override
  String get pos03d06fe851ed => 'Payment history';

  @override
  String get posdf9bcb350501 => 'Receiving history';

  @override
  String pos78bff8e79d25(String arg1) {
    return 'Receiving history ($arg1)';
  }

  @override
  String pos44a6903141ee(String arg1) {
    return 'Could not load receiving history: $arg1';
  }

  @override
  String get posa85af1e71e9b => 'Approval history';

  @override
  String get pos0fe8517ac3fd =>
      'Order history is not saved for offline mode yet.';

  @override
  String get posb4a4bddfcda6 => 'Status history';

  @override
  String get pos0aa338c39d33 => 'Rp ';

  @override
  String get posbebb06d5f701 => 'Rp 20.000';

  @override
  String get pos614dc907883d => 'Rp 50.000';

  @override
  String pos70272f418def(String arg1) {
    return 'Rp $arg1';
  }

  @override
  String pos0435fa2b2918(String arg1) {
    return 'Rp$arg1';
  }

  @override
  String get pos687b1a98c956 => 'Room';

  @override
  String get posa1c2ef9582aa => 'Room (optional)';

  @override
  String pos9a295c412a94(String arg1) {
    return 'Room $arg1';
  }

  @override
  String pos085e03d813e0(String arg1) {
    return 'Room: $arg1';
  }

  @override
  String get posf1238819f6ca => 'Damaged';

  @override
  String get pos97b4a8c1a3d2 => 'Damaged (quarantine required)';

  @override
  String get pos3fc271bd3070 => 'Severely Damaged';

  @override
  String get pos848c71c6e7fa => 'Shipping Damage';

  @override
  String get posf0dbf90859f6 => 'Minor Damage';

  @override
  String pos2d721657d7fb(String arg1) {
    return 'Delivery note $arg1';
  }

  @override
  String get posd59192b9c8f2 => 'SKU';

  @override
  String get pos0efd2187e8af => 'Internal SKU';

  @override
  String pos19aa65c6a13e(String arg1) {
    return 'SKU · $arg1';
  }

  @override
  String posee769816dc3e(String arg1) {
    return 'SKU: $arg1';
  }

  @override
  String posa8bae00d81f1(String arg1, String arg2) {
    return 'SKU: $arg1 • Stock $arg2';
  }

  @override
  String pos31737f83ebbc(String arg1) {
    return 'STATUS: $arg1';
  }

  @override
  String get posce2676cae242 => 'STOCK & WAREHOUSES';

  @override
  String get posab88dce84a40 =>
      'The system snapshots the selected balance on creation. Enter physical counts, unit conversions, and discrepancy reasons here. Stock changes only after approval and posting.';

  @override
  String get pos19c0ad1a1458 => 'On receipt';

  @override
  String get pos55cd4b5b2584 => 'Opening Inventory Balance';

  @override
  String get pos34793d42070a => 'Customer Credit Balance';

  @override
  String get pos3e5e25a71723 =>
      'Draft creation does not reduce the balance. Stock and loss journal entries are processed after approval.';

  @override
  String get pos6d045c1e5f71 => 'Invalid location balance for waste stock';

  @override
  String get pos62edee410efe => 'Item location balance unavailable';

  @override
  String poscb93757b9cc2(String arg1, String arg2) {
    return 'Current location balance: $arg1 $arg2';
  }

  @override
  String get poscd7e20e32092 => 'Location balance not found';

  @override
  String pos21462b1cd3e9(String arg1, String arg2, String arg3) {
    return 'Location balance: $arg1 → $arg2  •  Quantity $arg3';
  }

  @override
  String get pos50ead4249311 => 'Rack balances cannot be duplicated.';

  @override
  String get posc31885e11835 => 'Sales Forecasting';

  @override
  String get pos276d0542201d => 'Copy';

  @override
  String get pose4c5244bd1e0 => 'Copy number';

  @override
  String get pos94eecb57710c => 'Copy link';

  @override
  String get pos44ca06cb5561 => 'Thermal copy - the PDF contains full details.';

  @override
  String get pos55a7650d7df1 => 'Salon / Barbershop';

  @override
  String get pos722663e06443 =>
      'Connect the POS phone to Wi-Fi or enable a hotspot, then retry.';

  @override
  String get pos95b58818f0a3 => 'To date';

  @override
  String get pos2903a31e3470 =>
      'Suggested stock quantity when purchasing is needed';

  @override
  String get pos25153d5331af => 'One POS for every opportunity';

  @override
  String get posea9f626a17a4 =>
      'One drawer per store for authorized accounts; cashier identity is still recorded.';

  @override
  String get pos24726ff1ab88 => 'Unit';

  @override
  String get posde491a7e311f => 'Base unit';

  @override
  String get pos1792eb514851 => 'Base unit *';

  @override
  String get posba7cb71c0df6 => 'Base unit is required';

  @override
  String get posdb925237c56a => 'Purchase unit';

  @override
  String get pos72d7c8475f29 =>
      'I understand that active operations will not be changed.';

  @override
  String get pos44e0630b4e02 =>
      'I agree to Pantoo\'s Privacy Policy and Terms of Service.';

  @override
  String get pos28cba55d2aad => 'Scan';

  @override
  String get pos682ac2614b67 => 'Scan & Order';

  @override
  String get pos0335022fe9ad => 'Scan Barcode';

  @override
  String get pos5f5b67de90e9 => 'Scan barcode';

  @override
  String get posf017b1c0753e => 'Scan item barcode';

  @override
  String get pos6ebeb3af8b4f => 'Scan PO item barcode';

  @override
  String get posd4291e971b03 => 'Scan barcode with camera';

  @override
  String get pos1ae0ede21575 =>
      'Continuous scanning active · close this page when finished';

  @override
  String get pos75d2fe07b0b4 => 'Scan failed. Try again.';

  @override
  String get pose7711dd9beac => 'Rescan last code';

  @override
  String get pos719bf1496bac => 'Scan/enter a package barcode or leave blank';

  @override
  String get pose9916d957f01 => 'Scrap & Incidents';

  @override
  String get poseef74f939bac => 'Partial';

  @override
  String get posbd6d8425847c =>
      'Some dashboard data could not be loaded. Pull to retry.';

  @override
  String get pos92b05f3448b2 => 'Partially paid';

  @override
  String get posc9caf74cdab0 => 'Previous';

  @override
  String get posff9bb4f03176 => 'Medium';

  @override
  String get pos4b4720fe2684 => 'In Preparation';

  @override
  String get posf37c61ce775a => 'Generating SKU...';

  @override
  String get pos312e1053962d => 'Generating barcode...';

  @override
  String get posef457d1c5e7a => 'Simple';

  @override
  String get posa253a166b7f5 => 'Immediate';

  @override
  String get pos0c3c9b2741f5 => 'Customer Segment';

  @override
  String get pos5d19f1d2f443 => 'Segment: Regular';

  @override
  String posf35e7016437f(String arg1) {
    return 'Segment: $arg1';
  }

  @override
  String get posfebb840871f5 => 'Always choose through system dialog';

  @override
  String get pos2587dceb3eff => 'Next';

  @override
  String get pos148ec09c853e => 'Align stock rules';

  @override
  String get pos84b4b08d288b => 'More details';

  @override
  String get pos94388531abcf => 'Completed';

  @override
  String get pos56103c7818ce => 'Processing complete';

  @override
  String get pos342b00b06c09 => 'Production complete';

  @override
  String get posa62977f8f177 => 'Reservation end *';

  @override
  String get posdf1b466c3bdb => 'Complete the CAPTCHA to continue signing in';

  @override
  String get poseb491c27383d => 'Resolve manually';

  @override
  String get pos30e25467c147 => 'Complete order';

  @override
  String get pos70bd8bc4dfc1 =>
      'Complete these steps in sequence to keep stock, stores, cashiers, and shifts aligned.';

  @override
  String get pos4b18934a8a78 => 'Complete POS setup';

  @override
  String get posc097dcdfa01d => 'Resolve rejected transaction?';

  @override
  String get pos52226b8e3996 => 'Complete the previous seven steps first.';

  @override
  String get pos2a0ab753352f => 'Difference';

  @override
  String get pos50b9d8ad54f1 => 'Entire stock transfer received';

  @override
  String get pos40c34042d466 => 'Hide advanced options';

  @override
  String get pos383ff5de869b => 'Hide sidebar';

  @override
  String get pos42c76592cdc1 => 'All';

  @override
  String pos5ab6295dbc59(String arg1) {
    return 'All ($arg1)';
  }

  @override
  String get pos6c4ed1239a1d => 'All Branches';

  @override
  String get pos89487a13ab68 => 'All Inventory';

  @override
  String get pos2aca9f32c447 => 'All Cashiers';

  @override
  String get posd83b4ec645a9 => 'All Categories';

  @override
  String get pos61e3dd11f0d8 => 'All Price Levels';

  @override
  String get pos38a8d3e5d5dd => 'All Statuses';

  @override
  String get posf9245e99ba9f => 'All Stock';

  @override
  String get pos4bc9b7e5061e => 'All Time';

  @override
  String get pos74fce2388fe0 => 'All active';

  @override
  String get pos9468c7c38a1f => 'All reasons';

  @override
  String get posd6039e2c5ee0 => 'All items in the order will be removed.';

  @override
  String get posf6e4d87afd89 => 'All capacities';

  @override
  String get pos3ee43aaffaaf => 'All categories';

  @override
  String get posc0a87712b909 =>
      'All essential requirements are available. You can start serving transactions.';

  @override
  String get pos1fa2d4c18ea4 => 'All fields are required';

  @override
  String get posedfd39e720f3 => 'All locations';

  @override
  String get pos975a6c8b7bc0 => 'All resolutions';

  @override
  String get posf6debe4a2e8b =>
      'All prerequisites are ready. Follow the interactive highlights on the cashier page.';

  @override
  String get pos438928a078ae => 'All stations';

  @override
  String get pos30de1da3b483 => 'All stock';

  @override
  String get posc07ed2379764 => 'All dates';

  @override
  String get pos0c4dc379ee55 => 'All types';

  @override
  String get pos850f969f05d8 => 'All local transactions have been processed.';

  @override
  String get posfff6c547a425 => 'Handover';

  @override
  String pos2520218913bd(String arg1) {
    return 'Serial $arg1';
  }

  @override
  String pos78308eaba248(String arg1) {
    return 'Serial: $arg1';
  }

  @override
  String get posbb6c59a46705 => 'Serial number *';

  @override
  String pos4983e9639596(String arg1) {
    return 'Serial number for $arg1 is required';
  }

  @override
  String get pos418e05534d50 =>
      'The Google server configuration has changed. Close and reopen the app.';

  @override
  String pos440545e7a2a5(String arg1) {
    return 'Server returned a non-JSON response (HTTP $arg1).';
  }

  @override
  String posee023ea50beb(String arg1) {
    return 'Server error (HTTP $arg1). Please try again.';
  }

  @override
  String get posb7a0c72c7641 =>
      'Server unreachable. Non-cash payment was not saved because it requires online verification.';

  @override
  String get posb2e9666e3516 => 'Server did not provide a mobile refresh token';

  @override
  String get posdd98b0b9b3e6 => 'Server did not return a proof URL';

  @override
  String get pos641027584bdc => 'Server did not return a photo URL';

  @override
  String get pos2a59e8486f16 => 'Server did not return a pro forma URL';

  @override
  String get pos512b700c40d0 => 'Server did not return data';

  @override
  String get pos2acd1683a552 => 'Server did not return a transaction result';

  @override
  String get pos68f06b40165b => 'Service orders, technicians, vehicles';

  @override
  String get posf48e34c772d5 =>
      'POS session expired. Sign in again to connect the customer display.';

  @override
  String get pos51fc8b31070d => 'POS session unavailable. Sign in again first.';

  @override
  String get posa8e4eb047804 =>
      'Invalid POS session. Sign in again to connect the customer display.';

  @override
  String get pose56d33370578 => 'Could not verify session. Try again.';

  @override
  String get pos8a53ace562dd => 'Cashier session changed. Reload the shift.';

  @override
  String get posc901baf238d3 => 'Cashier session changed. Recheck the shift.';

  @override
  String get pos580f12f5433c =>
      'The cashier and account sessions will close. You must sign in again to use POS.';

  @override
  String get pos637079847c6d =>
      'Login session and offline PIN cache not found.';

  @override
  String get posdfd94253b50e => 'Could not save login session securely';

  @override
  String get pos9b7df86957fd =>
      'Login session not found. Please sign in again.';

  @override
  String get posa6793d1e0c7c => 'Stocktake session is closed.';

  @override
  String get pos7d6be8c431ea => 'Session expired or authentication failed';

  @override
  String get poscda725eb3c5e => 'Session expired. Please sign in again.';

  @override
  String get posb00ae356192a => 'Set API Endpoint';

  @override
  String get pos466e36cfa50d =>
      'Once active, transactions can begin and the shift can be closed after reconciliation.';

  @override
  String get posbca98a902aa8 =>
      'Save once required data is complete. The summary status updates from the server.';

  @override
  String get pos5b9e3f13a536 =>
      'After adding items, tap Pay to choose the payment method and invoice.';

  @override
  String get pos671488b2d5fb => 'After receiving';

  @override
  String get pos1f9ce43818de => 'Approve';

  @override
  String get pos805a4ef3a05a =>
      'Accept the Privacy Policy and Terms of Service to sign up.';

  @override
  String get posdbdcf1bd6a09 => 'Approve discrepancy report';

  @override
  String get pos8362cf86c76f => 'Approve return?';

  @override
  String get posf5015f6aba50 => 'POS setup incomplete';

  @override
  String get pos2116158c3784 =>
      'POS setup incomplete. Save this step, then return to the guide.';

  @override
  String get pos5c41c1f348dd => 'Asset Rental';

  @override
  String get pos469d5b183fdc => 'Shift';

  @override
  String get pos29ec3676a09b => 'Active Shift';

  @override
  String get posa5e670d32c94 => 'Cashier Shift';

  @override
  String get pos96e86a23186a => 'Cashier Shift Issue';

  @override
  String get pos6da0ceec2e04 => 'Active shift';

  @override
  String get pos7ffcb176cc14 =>
      'The active shift is at another store. The cart was not moved. Clear it to align the store.';

  @override
  String get pos4bdb422b576b => 'Shift active; transactions can begin.';

  @override
  String get pos156f00c76795 => 'Active shift found and restored.';

  @override
  String get pos08859689018b =>
      'Active shift found. Resume it or return to its outlet; no new shift is needed.';

  @override
  String get pos2c99482a7981 =>
      'Could not check shift. Check connection or PIN and retry.';

  @override
  String get pos98a50c991dd1 =>
      'Could not check shift. Check your connection or PIN, then retry.';

  @override
  String get posde0df7c46cc9 =>
      'Could not check shift. Check your connection or sign in again with a PIN, then retry. Do not open a replacement shift.';

  @override
  String get posa33c718829d0 =>
      'Shift cannot close while offline transactions remain';

  @override
  String get pos894b97fdf33f => 'Shift opened';

  @override
  String get pos7e0e86e2d1ed => 'Shift opened!';

  @override
  String get pose097451c0eb3 => 'Shift closed!';

  @override
  String get pos4dbcb8467f91 => 'Cashier shift not opened';

  @override
  String get posc11258dd9252 => 'Cashier shift opened';

  @override
  String posdabd37d4fec2(String arg1) {
    return 'Shift still active at $arg1';
  }

  @override
  String get pos7bb626d2ee62 => 'Shift per operator PIN';

  @override
  String get pos073e31a3bd3c => 'Shift in progress';

  @override
  String get posa073778c7067 =>
      'Shift does not match the cashier session. Reconnect to verify the shift.';

  @override
  String pos98c99bd51ac2(String arg1) {
    return 'Shift: $arg1';
  }

  @override
  String pos948945f10e42(String arg1) {
    return 'Shift: $arg1\n';
  }

  @override
  String get posd21509bf517a =>
      'Page shortcuts require operator permission. Navigation shortcuts are disabled while typing in forms.';

  @override
  String get pos1c79423e4e80 => 'Keyboard shortcuts';

  @override
  String get posb2be3c5f95c3 => 'Keyboard shortcuts (F1)';

  @override
  String get pos8151487829c2 => 'Pantoo POS keyboard shortcuts';

  @override
  String get pos791fdbfcb8c5 => 'Ready';

  @override
  String posd100bfb67f19(String arg1) {
    return 'Ready ($arg1)';
  }

  @override
  String get pose56826ba586f => 'Ready for Pickup';

  @override
  String get pos527ad1be2e11 => 'Ready for Pickup / Dispatch';

  @override
  String get posec0a910a0f17 => 'Ready to Use';

  @override
  String get pos6e739dd63407 => 'Ready for Dispatch';

  @override
  String get pos981dc927c290 => 'Ready to Serve';

  @override
  String get posa5cc9140a81a => 'Ready for pickup';

  @override
  String get pos93edf0e21787 => 'Ready to receive';

  @override
  String get posf691f231a836 => 'Set Up Business Profile';

  @override
  String get pos73b6f04c6ed8 => 'Prepare order';

  @override
  String get posc1f3fe0dd2fa => 'Please enter the customer\'s order';

  @override
  String get pos87dd92d7407a => 'Save';

  @override
  String get posc5d8fd5362b8 => 'Save & Submit';

  @override
  String get posed3d4bd0e9e1 => 'Save & Select';

  @override
  String get pos3511a0c6ae2e => 'Save & Apply';

  @override
  String get pose69db462d981 => 'Save & select';

  @override
  String get pos5591ae665d57 => 'Save Draft';

  @override
  String get posb37749958c1c => 'Save Return Draft';

  @override
  String get posd7e094de96dc => 'Save PIN';

  @override
  String get pos6d1d8f98614f => 'Save operator PIN';

  @override
  String get pos6676a7fa663e =>
      'Save the PIN. The operator can then be selected on the cashier access screen.';

  @override
  String get pos4d868b31685a => 'Save Customer';

  @override
  String get pos022708721646 => 'Save Receipt';

  @override
  String get posfd004c61af49 => 'Save Settings';

  @override
  String get pos03f7dda53d04 => 'Save Changes';

  @override
  String get posf9048f3b57b4 => 'Save Receipt Template';

  @override
  String get posf4f3de2168e3 => 'Save or pay';

  @override
  String get posf2b6ffa0fd34 =>
      'Save result unconfirmed. Use Restore return draft; do not create a replacement.';

  @override
  String get posf87e6c7fa4d2 => 'Save and validate';

  @override
  String get pos56cc656e2401 => 'Save draft';

  @override
  String get pos0d21cf8aebc6 => 'Return draft save result unconfirmed';

  @override
  String get pose01936b5dec8 => 'Return draft is still being saved.';

  @override
  String get posebe79e862972 => 'Save if unfinished';

  @override
  String get pos4b4ec71d0e25 => 'Save to Table';

  @override
  String get pos9410daa3e8ad => 'Save to catalog';

  @override
  String get pos850a0cd2d599 => 'Save decision';

  @override
  String get poscbcb630b45b8 => 'Save transfer';

  @override
  String get poscb9079833a1c => 'Hold order temporarily';

  @override
  String get posa24f4a17df98 => 'Save payment';

  @override
  String get posc2d472b10022 =>
      'Save changes, then return to the summary for the latest verification results.';

  @override
  String get posa5e4d00c96cb => 'Save order';

  @override
  String get pos48677f83dedc => 'Save order to table?';

  @override
  String get pos45df8c04b3a3 => 'Save current order';

  @override
  String get pos569a88c42e99 => 'Save product';

  @override
  String get pos1bbe87b2d71e => 'Save reservation & continue to payment?';

  @override
  String get pos1835ae239c74 => 'Save temporarily to resume later';

  @override
  String get pos445b4fe65c10 =>
      'Save after entering identity and stock location.';

  @override
  String get pos83b7d41ba189 => 'Save active store';

  @override
  String get posc74955195dfc => 'Save warehouse';

  @override
  String get pos7462bf74293a => 'Simulate order';

  @override
  String get posf4a8038902a9 => 'Cloud Sync';

  @override
  String get posc370e2b4c2d9 => 'Queue sync check completed';

  @override
  String get pose4e548e9dd8b => 'Previous sync interrupted';

  @override
  String get posd71ed5288850 => 'Sync now';

  @override
  String get pos861b9e39506d => 'Remaining';

  @override
  String get posa8a45e527a31 =>
      'The PO remainder changed after saving the request. The old request was not sent; check history and create a new receipt.';

  @override
  String pos9475d97d7968(String arg1) {
    return 'PO remainder: $arg1';
  }

  @override
  String get posf10e195d9d38 => 'Outstanding Balance';

  @override
  String get pos54260e5e875d => 'Outstanding payable';

  @override
  String get posc0fd40e41b59 => 'Outstanding balance';

  @override
  String get pos44b02638cf4e =>
      'Outstanding balance when the document was created';

  @override
  String posf7452c021e4b(String arg1, String arg2) {
    return 'Available remainder $arg1 $arg2';
  }

  @override
  String posb83023605a49(String arg1) {
    return 'Remaining $arg1';
  }

  @override
  String get posf4904a2aa306 => 'A complete system with powerful features.';

  @override
  String get pose141f778c439 =>
      'The system saves a snapshot of the sent PO. Delivery through an external app must still be completed through that channel.';

  @override
  String get pos6b21da6c193d =>
      'The system still creates an internal reference.';

  @override
  String pos6aba9ab9eb0a(String arg1, String arg2) {
    return 'System $arg1 $arg2';
  }

  @override
  String posafb095f644ad(String arg1) {
    return 'System $arg1; counted separately.';
  }

  @override
  String pos3f737224c118(String arg1, String arg2) {
    return 'System: $arg1 • Difference: $arg2';
  }

  @override
  String get pos3d85cb55da89 =>
      'Websites cannot request access to the system printer list. Open the sample PDF receipt and choose a printer through the browser print dialog.';

  @override
  String get pos91adb24a8159 =>
      'Incomplete snapshot received. Go back and reload the list before retrying.';

  @override
  String get posa0ebce5d1fff =>
      'Ambiguous rack snapshot. Create a new stocktake before counting.';

  @override
  String get pos2a3af98bc4a1 => 'Snapshot at payment';

  @override
  String get posfb0bf8a35d12 => 'Snapshot when the order was saved';

  @override
  String get pos23bd1710c9ef =>
      'Snapshot ready. Enter physical counts, save, then submit for approval. Stock is unchanged.';

  @override
  String get posed5bcef77ee0 => 'Modern POS for your business';

  @override
  String get posdb07d07df1ac => 'Active Cashier Staff';

  @override
  String get pos750b70e7921a => 'Station';

  @override
  String get pos4c740831fad8 => 'Production station *';

  @override
  String get posbae7d5be7082 => 'Status';

  @override
  String get pos260bc84885eb => 'PO status updated.';

  @override
  String get posae2d57447d2c => 'Print status';

  @override
  String pos3ee0e530bdfb(String arg1) {
    return 'Bluetooth print status uncertain. Check the printer paper before retrying. $arg1';
  }

  @override
  String get pose4b2dbd27139 =>
      'Print status uncertain. Check the printer paper before retrying.';

  @override
  String pos5e6e850d331f(String arg1) {
    return 'Terminal printer status uncertain. Check the printout before retrying. $arg1';
  }

  @override
  String pos09b1e41db353(String arg1) {
    return 'Print status uncertain. Check the printout before retrying. $arg1';
  }

  @override
  String get pos430beb670045 =>
      'Print status uncertain. Check the printer paper before reprinting.';

  @override
  String get pos70828e6b73c6 =>
      'Print status uncertain. The printer did not respond in time; check the printout before retrying.';

  @override
  String get pos1068901e5eab => 'Document status updated';

  @override
  String get posa993f0a3012e => 'Service item status updated';

  @override
  String get posae0c83d34577 => 'Could not process service item status';

  @override
  String get pos3d062ec9eebb => 'Membership status';

  @override
  String get poseee4706eb33b => 'Device connection status unknown.';

  @override
  String get pos318defda0303 => 'POS lock status unavailable';

  @override
  String get pos965dd1f4ec17 =>
      'Previous status does not match progress • receiving still allowed';

  @override
  String get pos803ffa3e7808 => 'Service status updated';

  @override
  String get poscd787856b1ff => 'Could not process service status';

  @override
  String get pos9e279437f53e => 'Payment status is recorded only by Finance.';

  @override
  String get pos81449d4aa3f4 => 'Order status';

  @override
  String get pos67c6c3bc4519 => 'Order status changed';

  @override
  String get pos80c2b8011e85 => 'Could not process order status';

  @override
  String get pos8e8818b099b2 => 'Reservation status updated';

  @override
  String get posccd2f79d3688 => 'Could not process reservation status';

  @override
  String get pos2b855e28ddaa => 'Return status updated';

  @override
  String get pos18ba5c874c90 => 'Completion status';

  @override
  String get posc3aefe57a641 =>
      'Shift status comes from the latest saved data. Offline transactions still await server verification during sync.';

  @override
  String get pos7ceb6266a330 => 'Server sync status needs checking';

  @override
  String pos09cf25171d0b(String arg1) {
    return 'Sync status: $arg1';
  }

  @override
  String get pos9ab5b57e2ee0 => 'Stock status';

  @override
  String get posa4a06d4f622c => 'Transfer status updated';

  @override
  String get pos8e92361ede90 =>
      'Transfer status changed. Reload the list before editing.';

  @override
  String get pos2980c2cf8251 => 'Status: Offline';

  @override
  String get pos989f71bddd67 => 'Status: Online';

  @override
  String pos52fb707d5447(String arg1) {
    return 'Status: $arg1';
  }

  @override
  String posd3f7af1f6d12(String arg1, String arg2) {
    return 'Status: $arg1 · $arg2';
  }

  @override
  String get pose2b5665a464c => 'Stocktake';

  @override
  String get pose3cf2afbdddd => 'Stock';

  @override
  String get pos1847b1f21884 => 'Stock & Units';

  @override
  String get pos7fd8b3f8b4fb => 'Stock (read-only)';

  @override
  String get pos710ec3c4fe69 => 'Out of Stock';

  @override
  String get pos2be0b0b1dbb3 => 'Inventory Stock';

  @override
  String get pos68e480371d62 => 'Stocktake';

  @override
  String get pos42321abe7200 => 'Low Stock';

  @override
  String get posf98b1faeb0e2 => 'Current Stock';

  @override
  String get pos346dd6087ca1 => 'Waste Stock';

  @override
  String get pos8c00059d75a7 => 'Available Stock';

  @override
  String get pos6221a27d5a5d => 'Insufficient Stock';

  @override
  String get pos5d8949197719 => 'Product opening stock';

  @override
  String get pos5a32fa04b2af =>
      'Product opening stock is ready to start selling.';

  @override
  String get pos21af179ea077 => 'Stock adjusted';

  @override
  String get pos1c03f3cf2a63 =>
      'The server will process stock and financial effects.';

  @override
  String get pos266e05dff2d2 => 'Stock can be used by the outlet cashier';

  @override
  String get pos51b774badd39 =>
      'Stock reversed; check the reversal journal entry.';

  @override
  String posdf3a8d32e918(String arg1) {
    return 'Stock returned, but reversal journal entry failed: $arg1';
  }

  @override
  String get pos63e60a9d4a35 => 'Stock tracked by serial number';

  @override
  String get pos1c8a7e170526 =>
      'Stock received, but cost journal entry needs retrying';

  @override
  String get pos60af176a330a => 'Latest physical stock';

  @override
  String get pos8544030a617e => 'Could not update stock';

  @override
  String get posc9cffe0a7181 => 'Out of stock';

  @override
  String pos882f6d381755(String arg1) {
    return 'Insufficient local stock for $arg1. Check stock while online.';
  }

  @override
  String get posaf3ec6b9dbd2 => 'Maximum stock';

  @override
  String get pos7a11751ba810 => 'Maximum stock cannot be below minimum stock';

  @override
  String get pos4304912d8a8e => 'Stock follows transactions and locations';

  @override
  String get pos52db5a21b33f => 'Low stock (1–10)';

  @override
  String get pose98220c91cd4 => 'Minimum stock';

  @override
  String get pos3d062b4adc05 => 'Stocktake unavailable';

  @override
  String get posbc11dbfb3dda => 'Stock is always stored in this unit.';

  @override
  String posee3f877ea456(String arg1) {
    return 'System stock: $arg1';
  }

  @override
  String pos2de86e144e10(String arg1) {
    return 'Stock has been returned, but check the reversal journal entry: $arg1';
  }

  @override
  String pos39e38f288da4(String arg1) {
    return 'Stock has been processed, but check the cost journal entry: $arg1';
  }

  @override
  String pos01eebd959af3(String arg1) {
    return 'Stock has been processed, but check the journal entry: $arg1';
  }

  @override
  String posa8ad9c0dfe6e(String arg1) {
    return 'Stock has been received, but check the journal entry: $arg1';
  }

  @override
  String get posdaf83725281e => 'Available stock';

  @override
  String get posb8b02b77a74b => 'Stock not tracked';

  @override
  String get pos18f6d7a4344b => 'Stock not found';

  @override
  String pos0f3c48a06258(String arg1) {
    return 'Stock $arg1';
  }

  @override
  String posfb314505e100(String arg1) {
    return '$arg1 is out of stock';
  }

  @override
  String posda4c6efa512d(String arg1) {
    return 'Insufficient stock for $arg1';
  }

  @override
  String posb84bbc8a4359(String arg1, String arg2) {
    return 'Insufficient stock for $arg1 in unit $arg2';
  }

  @override
  String get pos9596e59f4d65 =>
      'Stock/status processed, but cost journal entry is not confirmed. Check journal details.';

  @override
  String get posef10e37e5405 =>
      'Receipt not printed because no printer is selected. The transaction succeeded; print it later.';

  @override
  String pos1552d665f55b(String arg1) {
    return 'Transaction receipt $arg1 from Pantoo POS.';
  }

  @override
  String posb8805613da76(String arg1) {
    return 'Receipt $arg1';
  }

  @override
  String pos4301300bea4d(
    String arg1,
    String arg2,
    String arg3,
    String arg4,
    String arg5,
    String arg6,
    String arg7,
    String arg8,
    String arg9,
    String arg10,
    String arg11,
    String arg12,
    String arg13,
    String arg14,
    String arg15,
  ) {
    return 'Receipt $arg1\n$arg2$arg3$arg4$arg5$arg6$arg7\n$arg8\n\nSubtotal: $arg9\n${arg10}Total: $arg11\nPayment: $arg12\nPaid: $arg13\n$arg14${arg15}Thank you.';
  }

  @override
  String get pos7c355d6ded0e => 'Subtitle (Line 2)';

  @override
  String get pos3db67bab4761 => 'Subtitle';

  @override
  String get pos496773411e93 => 'Could not save invoice submission';

  @override
  String get pos97f7359ed801 => 'Subtotal';

  @override
  String poseb08b632f2d5(String arg1) {
    return 'Subtotal    $arg1';
  }

  @override
  String pos7eef271ab44c(String arg1) {
    return 'Subtotal  Rp $arg1';
  }

  @override
  String get posbc469e0842ff => 'Return subtotal';

  @override
  String get posecee7d783116 => 'An open PO already exists';

  @override
  String get posd2f1691a6064 => 'Already allocated';

  @override
  String get pos9081b592591b => 'Already allocated/resolved';

  @override
  String get pos8f5b2a4c8e87 => 'Already picked up';

  @override
  String get pos3c78f49c2760 => 'Already paid';

  @override
  String get pos65547f8b0596 => 'Already paid by Finance';

  @override
  String get pos485abda51c24 => 'Reviewed';

  @override
  String get pos59342aa97b3f => 'Already have an account? ';

  @override
  String get posc554a5971e09 => 'Success!';

  @override
  String get pos4a35306efdc4 => 'Funding source';

  @override
  String get pos7fe3f6a28b35 => 'Transfer source';

  @override
  String get posbd176eff4e37 => 'Stock transfer source';

  @override
  String get poscd35adb78547 => 'Stock source';

  @override
  String get pos61c9cd215c5d => 'Stock source not recorded';

  @override
  String get pos0feff31b55c9 => 'Transaction sources available at the cashier.';

  @override
  String get pos55edd462872a => 'Supplier';

  @override
  String get pos396c65e60e58 => 'Supplier *';

  @override
  String get poscb0f469f333b => 'Supplier / Delivery';

  @override
  String get posf530daa061ad => 'VAT-Registered Supplier';

  @override
  String get posfad4b83e3b5c => 'Supplier not saved';

  @override
  String get pos2c04998514d5 => 'Supplier not found';

  @override
  String pos31dc38aa1f0a(String arg1) {
    return 'Supplier: $arg1';
  }

  @override
  String pose887e1053f93(String arg1, String arg2, String arg3) {
    return 'Supplier: $arg1\nBranch: $arg2\nTotal: $arg3\n\n';
  }

  @override
  String get pos3ff56bafe041 => 'Build your own operating workflow';

  @override
  String get pos5043e33cb064 => 'Payment terms';

  @override
  String get pos5103f5b202bf => 'FULFILLMENT TYPE';

  @override
  String posf584192c76e1(String arg1) {
    return 'TOTAL    $arg1';
  }

  @override
  String get pos5a9710152fc9 => 'Bag tag';

  @override
  String pos60cb53587d72(String arg1) {
    return 'Tag: $arg1';
  }

  @override
  String get pos40bbe135d3d3 => 'Bills';

  @override
  String get poscb40220c0a55 => 'Supplier Bills';

  @override
  String get pos92ccc2918c68 =>
      'This bill is read-only in the PO workspace. Manage payments in Finance Web.';

  @override
  String get posb628d14b320c =>
      'This bill is now an invoice. Record settlement through Receivables in Finance.';

  @override
  String get pos553785145ba6 => 'No bills are available for this PO yet.';

  @override
  String pos1a57bf89a651(String arg1) {
    return 'Bill $arg1';
  }

  @override
  String get pos6ad5100db871 => 'This Year';

  @override
  String get pos68efe193b73e => 'Takeaway';

  @override
  String get posa44eb3d1808f => 'Add';

  @override
  String get pos6c6f45d37def => 'Add Inventory';

  @override
  String get pos755cf8a9ca03 => 'Add Vehicle';

  @override
  String get pos99ca62429533 => 'Add Table';

  @override
  String get pos6e5442a4cfe5 => 'Add New Table';

  @override
  String get pos019dd35046d2 => 'Add Partner';

  @override
  String get pos9a338a7e55c9 => 'Add Stock Transfer';

  @override
  String get pos56c5bd1400ce => 'Add Outlet';

  @override
  String get pos2e73c6e4a5c7 => 'Add Customer';

  @override
  String get pos23cd385042fe => 'Add Product';

  @override
  String get pos4160fba23eb0 => 'Add Promotion';

  @override
  String get pos6482219b950b => 'Add New Promotion';

  @override
  String get pos4e362518ed1c => 'Add Return';

  @override
  String get pos7010b9522fd5 => 'Add Warehouse';

  @override
  String get pos44a863c60f91 => 'Add to or remove from favorites';

  @override
  String get posb3f10ee4007c => 'Add item';

  @override
  String get pos037fbc1dfe7d => 'Add transfer items';

  @override
  String get pos498e8fb630b1 => 'Add cost';

  @override
  String get posf38998f2d56f => 'Add estimate';

  @override
  String get posf1458c4deaa0 => 'Add category';

  @override
  String get pos96b75014ae96 => 'Quick add category';

  @override
  String get pos29f1ec9a570b => 'Add stock location';

  @override
  String get pos0cd32f8dcafe => 'Add payment method';

  @override
  String get pos30483a1c75bb => 'Add new customer';

  @override
  String get pos6031696a08e1 => 'Add new product';

  @override
  String get pos1b3001928c79 => 'Quick add supplier';

  @override
  String pos56c80ff62e6d(String arg1) {
    return 'Add $arg1';
  }

  @override
  String posee8ce59373ea(String arg1) {
    return 'Add $arg1 to cart';
  }

  @override
  String get posaf4a6e6a61f5 => 'Add items and enter valid quantities';

  @override
  String get pos0e9808622c06 =>
      'Add branches or warehouses that physically hold your business stock.';

  @override
  String get pos14ab770d31dd => 'Attach receipt photo';

  @override
  String get posf28de2fc76b0 => 'Add to inventory value';

  @override
  String get posc0ef565f6c46 =>
      'Add tables and their seating capacity to start accepting dine-in orders.';

  @override
  String get pos0a20820582f3 =>
      'Add tables from Map & Table Settings to process dine-in orders.';

  @override
  String get posf9ed1378315b => 'Add at least one item.';

  @override
  String get pos7c4d863b6e3e =>
      'Add at least one active product, service, or bundle.';

  @override
  String get pos3f0c2dfed6fd =>
      'Add an outlet and link it to an inventory location so the cashier can operate.';

  @override
  String pos954c7b7880aa(String arg1) {
    return 'Add $arg1 to favorites';
  }

  @override
  String get posc471ab3cb8ef => 'Kitchen Display';

  @override
  String get posfcf9d787a451 => 'Kitchen display not enabled';

  @override
  String get posa9d494637756 => 'Show Organization Logo';

  @override
  String get pose9e2bf944744 => 'Show Store Logo';

  @override
  String get pos80a8257d82b3 => 'Show as grid';

  @override
  String get poscef74203b616 => 'Show as cards';

  @override
  String get pos1ae84586da02 => 'Show as list';

  @override
  String get pos54109c62b2f0 => 'Show as table';

  @override
  String get posf537d54d0add => 'Show sidebar';

  @override
  String get pos77f0b190ab89 => 'Mark as read';

  @override
  String get pos20c6fad9ebd2 => 'Mark ready';

  @override
  String get pos5b62a882a596 => 'Mark ready for pickup';

  @override
  String get pos97c6fd355f4c => 'Mark ready for dispatch';

  @override
  String get pos28b4cc7ba754 => 'Mark ready to serve';

  @override
  String get posac8b880f0ed5 => 'Mark as served';

  @override
  String get pos807151f245bd => 'Date';

  @override
  String get pos131138e3eed6 => 'Date & Time';

  @override
  String get pos501be77e1c34 => 'End Date';

  @override
  String get posbb48601d724d => 'Start Date';

  @override
  String get posdb24b06fb8ef => 'PO Date';

  @override
  String pos69d6ab263540(String arg1) {
    return 'PO date: $arg1';
  }

  @override
  String get poscaeb6107474a => 'Order Date';

  @override
  String pos5415cb31728d(String arg1) {
    return 'Physical date cannot be before dispatch on $arg1.';
  }

  @override
  String get posebfbac7f1c35 => 'Invoice date (YYYY-MM-DD)';

  @override
  String get posff1b197f16ea =>
      'Invoice date must be a valid calendar date (YYYY-MM-DD)';

  @override
  String get posd54b6df76995 => 'Supplier invoice date';

  @override
  String get pos3d3a31237bf5 => 'Due date';

  @override
  String get pos12e331f09cb3 => 'Expiry date (optional)';

  @override
  String get posce03e667a236 => 'Expiry date *';

  @override
  String pos3d3dc9c404be(String arg1) {
    return 'Expiry date for $arg1 cannot be before the receipt date';
  }

  @override
  String posdb30b8965c81(String arg1) {
    return 'Invalid expiry date for $arg1';
  }

  @override
  String get pos08206fcf8a87 => 'Incident date';

  @override
  String get pos0bcfc3c95d98 => 'Stocktake date *';

  @override
  String get pos045865863406 => 'Payment date';

  @override
  String get posee1938d41d9b => 'Payment date *';

  @override
  String get pos30ded67f550b => 'Purchase date *';

  @override
  String get posaf9ed8959b4d => 'Posting date';

  @override
  String get pos0e6d46526797 => 'Cost posting date (YYYY-MM-DD)';

  @override
  String pos67ec666ad538(String arg1) {
    return 'Posting date is before the previous movement/resolution ($arg1).';
  }

  @override
  String get pose6a950933ff5 =>
      'Posting date cannot be before physical receipt.';

  @override
  String get pos956df79c0998 => 'Receipt date';

  @override
  String get pos2cb9669941f4 => 'Physical receipt date';

  @override
  String get pose76f1b421a66 => 'Dispatch date';

  @override
  String get posab8b37663768 => 'Order date';

  @override
  String get posa1a64376f020 => 'Return date';

  @override
  String get pos6d63436f523e => 'Fixed date';

  @override
  String get pos8732d88a75f3 => 'Date cannot be in the future.';

  @override
  String get pos81c93eadaee7 => 'Transfer date (YYYY-MM-DD)';

  @override
  String get posc87c804724f5 =>
      'Date, delivery note, building, room, rack, and notes';

  @override
  String get pos12f948b60d02 => 'Date: 09/09/2026 14:30';

  @override
  String pos54ec6781af4f(String arg1) {
    return 'Date: $arg1';
  }

  @override
  String get posbc69375eb9f6 => 'No Rounding';

  @override
  String get pos20b8d29a2f68 => 'No batch';

  @override
  String get pos39a8e7188576 => 'No details';

  @override
  String get pos4a57a4e8c738 => 'No expiry date';

  @override
  String get pos455b1c47f174 => 'No code';

  @override
  String get pos6b15ca9b9ecd => 'No table';

  @override
  String get pos3c0eda1efc57 => 'No phone number';

  @override
  String get pos14b38f55305d => 'No customer';

  @override
  String get pose16378fd2ee7 => 'No approval (as permitted)';

  @override
  String get posaecde974c63d => 'Pull down to reload.';

  @override
  String get pos6044f3b894da => 'Could not open the Web Order link.';

  @override
  String get posdea33388f0d2 => 'Proof link (optional)';

  @override
  String get pos1c308860b4fd => 'Proof link must be a valid http/https URL.';

  @override
  String get pos0cdccef7be07 => 'Customer display link copied';

  @override
  String get pos2e43636edafe =>
      'Invalid customer display link. Create a new pairing in POS.';

  @override
  String get posa4167d79d806 => 'Table link copied.';

  @override
  String get pos14b38fc11a3b => 'Pairing link created below.';

  @override
  String get pos00edd80ae2b2 =>
      'Link the store warehouse and display to the same POS outlet in Warehouses & Locations.';

  @override
  String get pose62855ffc2cc => 'Press \"Create pairing link\" below.';

  @override
  String get pos5c0323d8d3b3 =>
      'Press \"Disconnect\" when the cashier is finished or before switching operators. The link will be disabled.';

  @override
  String get pos8b5144cc4869 => 'Technician / staff';

  @override
  String get posf3d9ea2fc63b => 'Assigned technician / staff';

  @override
  String pos4d67ce5fd380(String arg1) {
    return 'Technician / staff: $arg1';
  }

  @override
  String get pos396dc0e2976f => 'Phone';

  @override
  String get posece97dedc009 => 'Phone (optional)';

  @override
  String get pos0e7c0c9f4a88 => 'Credit / Receivables';

  @override
  String get pos8b492afb0f02 =>
      'Choose how promotions and manual discounts are applied';

  @override
  String get pos827f2855ac2a => 'Set selling price';

  @override
  String get pos81c9388d21a8 =>
      'Choose a physical product or bundle so stock rules are applied correctly.';

  @override
  String get pos3cb303bd2ec7 => 'Light';

  @override
  String get pos9ff8760b6d49 => 'Apply';

  @override
  String posdd94a4d861f7(String arg1) {
    return 'Apply ($arg1)';
  }

  @override
  String get pos77a4d402549f => 'Apply cost draft';

  @override
  String get posd70b31cde451 => 'Apply code after typing';

  @override
  String get posd79b3f5531eb => 'Open';

  @override
  String get posc6a1492ff72c => 'Connected';

  @override
  String get pos123eb4b1f4a6 => 'Connected to Main Outlet';

  @override
  String get pos328534274450 =>
      'Connected · cart changes appear automatically.';

  @override
  String get posa40d8bc2696a => 'Receive';

  @override
  String get pos3c23586cca04 => 'Receive Goods';

  @override
  String get pos9138ecd0cc2c => 'Receive Transfer';

  @override
  String get posa5a0eefe554a => 'Receive Stock Transfer';

  @override
  String get pos918f7e4bada8 => 'Receive All';

  @override
  String get pos13084f0060ba => 'Receive Remainder';

  @override
  String get pos2a56109caa07 => 'Receive this quantity';

  @override
  String get pos85d56e26d84f => 'Thank you for shopping with us.';

  @override
  String get pos5b2653468523 => 'Thank you.';

  @override
  String get pos8bf051a528b4 => 'Receive stock transfer';

  @override
  String posfd9cce7e760d(String arg1) {
    return 'Receive $arg1';
  }

  @override
  String get posa95fd00d6f74 => 'Occupied';

  @override
  String get posb80a611ada31 => 'Occupied first';

  @override
  String get posf2f8ad1a33a3 => 'Server error';

  @override
  String get pose38a09bee38f => 'Server error (GraphQL)';

  @override
  String get posd53ab0343c76 => 'System error';

  @override
  String get posd851d69b35dc => 'An unexpected error occurred';

  @override
  String get pos9825574c27d3 => 'Delivered';

  @override
  String get pose052ade153b0 => 'Too many attempts. PIN locked for 15 minutes.';

  @override
  String get posa91276a45d32 => 'Include paid / credited';

  @override
  String get pos11f75ee33253 => 'Installments';

  @override
  String get pos8bc422f90578 => 'Payment installments';

  @override
  String posb4fffbba8098(String arg1, String arg2) {
    return 'Installment $arg1 · remaining $arg2';
  }

  @override
  String pos513371e1f08c(String arg1, String arg2, String arg3) {
    return 'Installment $arg1: $arg2 / $arg3';
  }

  @override
  String posaed34e9e9854(String arg1) {
    return 'Installment: $arg1';
  }

  @override
  String get pos0fa74526920d => 'Centralized';

  @override
  String get pos227ffef55dc7 => 'Available';

  @override
  String pos355bebfd5205(String arg1, String arg2) {
    return 'Available $arg1 $arg2';
  }

  @override
  String pos6551fa1c3fd7(String arg1, String arg2, String arg3) {
    return 'Available: $arg1 $arg2 • $arg3';
  }

  @override
  String get posa6c7a3f94cda => 'Validated';

  @override
  String get pos1df0537d9de5 => 'Test print';

  @override
  String get posba1ba5c3dedc => 'Bluetooth test print';

  @override
  String get pos4e9e8afc4161 => 'Could not open test print';

  @override
  String get pos7a5e10c3ec8f => 'Create PO Anyway';

  @override
  String get pose28c8f9b6faa => 'Unfit for Use';

  @override
  String get pos02d9f6225cc9 => 'Not as Ordered';

  @override
  String get posd14b80e2cab6 =>
      'No POs ready to receive on this page. Search a PO number/supplier or open the next page.';

  @override
  String get pos07937b27ef30 => 'No kitchen queue';

  @override
  String get pos25a5ed84de7b => 'No items remain eligible for return.';

  @override
  String get pos16b44b53e177 => 'No return draft to restore.';

  @override
  String get pos3c61b2617f65 =>
      'No POS invoices match your search. Unpaid orders are not Finance receivables.';

  @override
  String get posf2c7cb131978 =>
      'No internet connection. Please check your network.';

  @override
  String get pos23fdb360f8b3 => 'No tables with this capacity.';

  @override
  String get pos0ebce40e26fd => 'No valid tables to print.';

  @override
  String get pos0be0bfd5091d => 'No transfers need receiving';

  @override
  String get poscd430fcd869c => 'No active orders';

  @override
  String get pos372c46a6aa3b => 'No orders match this filter';

  @override
  String get pos7cb0145c32a4 => 'No products found';

  @override
  String get pos276765701c83 => 'No matching products';

  @override
  String get posb634c27cda07 => 'No references match your search.';

  @override
  String get pos08e988bdbdd9 =>
      'No active bank accounts. Choose cash or bank draft, or activate a bank account.';

  @override
  String get posb988e0cefb12 => 'No item details';

  @override
  String get pos8ef1715375a7 => 'No remaining goods to receive';

  @override
  String get posd3507ee22ea4 =>
      'No unallocated remainder. Check discrepancy reports awaiting a decision.';

  @override
  String get pos3b85b962d8dd =>
      'No unallocated remainder; wait for discrepancy decisions.';

  @override
  String get posb9423ee93d01 => 'No transactions with the selected status.';

  @override
  String get pos1e33bb47437a => 'No pending sales transactions.';

  @override
  String get posfd5faee84f1b =>
      'Could not connect to the customer display service.';

  @override
  String get poseb6d895fe4e7 => 'Not tracked';

  @override
  String get posd44bf57a32ac => 'Not selected';

  @override
  String get pos8034781bbb27 => 'No-show';

  @override
  String get posebc30faa0fa1 => 'No preparation required';

  @override
  String get poseb71f28b76dd => 'Membership tier';

  @override
  String get pos02a84571b7f3 => 'PO Timeline';

  @override
  String get pos4c20e74480b6 => 'Actions';

  @override
  String get pos3801023d0e64 => 'Stock action';

  @override
  String get posf74b2e01d304 => 'Improve your business productivity today.';

  @override
  String get pos3c2875091e3c => 'Review';

  @override
  String get posf0aed10f9451 => 'Review & resend';

  @override
  String get posb666fefb0fb8 => 'Fulfillment Type';

  @override
  String get pos39695d6fab24 => 'Credit type';

  @override
  String get pos5b2ea9d58638 => 'Customer type';

  @override
  String get posfc101b9f5bc8 => 'Fulfillment type';

  @override
  String pos0a10d64b8683(String arg1) {
    return 'Fulfillment type: $arg1';
  }

  @override
  String get pos7539a5f64c2c => 'Warehouse type';

  @override
  String get pose187aa4cc6cf => 'Reorder point';

  @override
  String get posd7ec691ffd26 => 'Reorder point cannot exceed maximum stock';

  @override
  String get posf2de7d5013d2 => 'Invalid login token';

  @override
  String get posba59de499bef => 'Stores';

  @override
  String get posbf2a3a380ae5 => 'Cashier Store';

  @override
  String get posc4a098109244 => 'Active POS store';

  @override
  String get pos80f6d6639a16 => 'Main Store';

  @override
  String get pos881045d882c0 =>
      'The active store is not linked to a stock location. Check the store and cashier shift.';

  @override
  String get pos9cc793d53ed1 => 'Active store unavailable';

  @override
  String get pos8a1efe9dca0c => 'Active store unavailable for tables.';

  @override
  String get pos3a3cb51969d1 => 'Active store unavailable for transactions';

  @override
  String get pos9ef09d22b518 => 'Active store unavailable.';

  @override
  String get posedc717c12636 => 'Active store not found';

  @override
  String get pos4f103360274e =>
      'Store is not linked to an active sales location';

  @override
  String get posf7072aa80587 => 'Store unavailable';

  @override
  String get pos41e84ba3fd33 =>
      'Shift store is not linked to an active warehouse';

  @override
  String get pos49c6b2654fba => 'Store: Main Store';

  @override
  String pos25b5fa1d18b0(String arg1) {
    return 'Store: $arg1';
  }

  @override
  String get pose2f73daf8ad0 => 'Reject';

  @override
  String get pos5b45c628dde2 => 'Reject return';

  @override
  String get pos84c23558e454 => 'Reject transaction';

  @override
  String get pos661e54fd9138 => 'Reject local transaction?';

  @override
  String get pos5e462813f581 =>
      'The button activates after all requirements are complete. Steps without access must be completed by a POS administrator.';

  @override
  String get posb25928c69902 => 'Total';

  @override
  String get pos712ac5744241 => 'Invoice Total';

  @override
  String get pos0edbc4a83d06 => 'Total Payments';

  @override
  String get posabe6ac2824da => 'Total Sales';

  @override
  String get pos8396d2543918 => 'Total Products';

  @override
  String get pos0fc983ed2d5d => 'Total Invoice Amount';

  @override
  String get posa46b1987023b => 'Total Transactions';

  @override
  String get pos9cfd7ea58a5f =>
      'Totals are calculated in base units. Factors come from the item master.';

  @override
  String get posdd4e80fe392d => 'Invoice total';

  @override
  String posd6f7fd5de931(String arg1, String arg2) {
    return 'Physical total: $arg1 $arg2';
  }

  @override
  String get pos0a574329b34f => 'Item count';

  @override
  String get posc3719a52f6da =>
      'Total batch quantity must equal the received/reported quantity.';

  @override
  String get posd7fc4f1f38e0 =>
      'Total unit conversion quantity must equal the item quantity.';

  @override
  String get posd1325b552564 =>
      'Total active payments when the document was created';

  @override
  String get pos387705b1005d =>
      'Server order total differs from the device estimate. Review the order before accepting payment.';

  @override
  String get posa010ebebdaa7 => 'Return total';

  @override
  String get posbd97f3163d03 =>
      'Server total differs from the cash recorded offline. Reconcile the invoice and physical cash.';

  @override
  String get pos98939e557aaf => 'Total bill';

  @override
  String get posd7bf2cf67fad => 'PO bill total';

  @override
  String get pos7d383dc5f80b => 'Highest total';

  @override
  String posbd45ba0ddb67(String arg1) {
    return 'Total $arg1 Products';
  }

  @override
  String pos708b9937b7f6(String arg1, String arg2, String arg3, String arg4) {
    return 'Total $arg1 · Paid $arg2\nCredit $arg3 · Outstanding $arg4';
  }

  @override
  String pos1b58713d0d0e(String arg1) {
    return 'Total: Rp $arg1';
  }

  @override
  String pos596318639b9f(String arg1) {
    return 'Total: $arg1';
  }

  @override
  String get posb0e1aaa60268 => 'Stock tracking';

  @override
  String get posa30e42dfeca0 =>
      'POS stock tracking must be enabled for this Inventory profile.';

  @override
  String get pos4c697c1208a6 => 'Stock tracking disabled';

  @override
  String get pos05ad114b6398 => 'Transactions';

  @override
  String get pos5706aca66e97 => 'Transactions & Sales';

  @override
  String get posfd0591b93e49 => 'Your transaction is complete.';

  @override
  String get posf24c8324445b => 'New Transaction';

  @override
  String get posa89cb868f629 => 'Quick Transaction';

  @override
  String get pos099aef52697a => 'Rejected Transactions';

  @override
  String get pos7b6056658137 => 'Today\'s Transactions';

  @override
  String get posb653b31b8eaf => 'Last Transaction';

  @override
  String get pos2e839e8b2d7d => 'Cash Transactions';

  @override
  String get pos1580dc07676b =>
      'Transaction not saved on this device. Check available storage and try again.';

  @override
  String get pos631991be1f51 =>
      'Transactions and invoices created at the cashier appear here.';

  @override
  String get poscaddb4f7b210 =>
      'Transactions with supervisor PIN authorization must be processed online';

  @override
  String get pos752ce2ad63e3 => 'A customer is required for this transaction';

  @override
  String get pos7dfa63215c99 => 'Transaction already on the server';

  @override
  String get pos6a2d684ff284 => 'Transaction processed successfully.';

  @override
  String get pos986d3ab97aef => 'Transaction processing completed';

  @override
  String posb9fb0286e5f6(String arg1) {
    return 'Transaction $arg1';
  }

  @override
  String get poscbb4cc49824b => 'Transfer';

  @override
  String get pose275aadefb10 => 'Bank Transfer';

  @override
  String get posc0f0a2dc1a3e => 'Stock Transfer';

  @override
  String get pos3e1af964e646 => 'Bank transfer';

  @override
  String get pose257882eba93 =>
      'Direct transfer: destination stock increases and the document completes on dispatch.';

  @override
  String get pos5ad1af2acc27 =>
      'Transfer complete. Check journal details if costs apply.';

  @override
  String get pos731b69a0bb45 => 'Transfer not found or inaccessible.';

  @override
  String get posa055a39bd588 =>
      'Transfer is no longer in transit. Go back and reload.';

  @override
  String pos1a266eba7d88(String arg1) {
    return 'Transit: $arg1';
  }

  @override
  String get pos004cad660b83 => 'Sales Trends';

  @override
  String get pos060c7c7202e1 => 'Stocktake purpose / notes';

  @override
  String get posdffe7a4163fe => 'Purpose / notes';

  @override
  String get pos02ccf7770f37 => 'Transfer destination';

  @override
  String get pose69bebecddc7 => 'Stock transfer destination';

  @override
  String get pos0a78745dd62b => 'Down payment request purpose is required.';

  @override
  String get posd0d530dc9610 =>
      'The PO stock destination is unavailable for receiving. Check the PO location and inventory settings.';

  @override
  String get pos81edf3c4ac59 => 'Enter manually';

  @override
  String get posa95263a809a0 => 'Cash';

  @override
  String get posea87feb3a83f =>
      'Wait for \"Display connected\", then add products to the cart to confirm the display updates.';

  @override
  String get pos06cde76b08c5 => 'Close';

  @override
  String get posf25f39d6a1b4 => 'Close & free table';

  @override
  String get pos198d04f3123b => 'Close Shift';

  @override
  String get pos1c6d3d899f61 => 'Close with Discrepancy';

  @override
  String get pos7e2c5bec7ea0 => 'Close conversions';

  @override
  String get pos065cf00b7076 => 'Close guide';

  @override
  String get pos7d5b3fcdabe8 => 'Close order & free table';

  @override
  String get pos90cfcd5e19e2 =>
      'Close the active shift before selecting another store.';

  @override
  String get posb0fc2128a9e8 => 'Close sidebar';

  @override
  String get posae7b61300bc2 =>
      'The app build contains an invalid Web Order URL.';

  @override
  String get pos54e4b285b105 => 'MAIN';

  @override
  String get pos370bbfc4c6f3 => 'Opening Cash (Rp)';

  @override
  String get pos8a15664747c4 => 'Exact Amount';

  @override
  String get pos5d88fa8ca6f5 => 'Amount received';

  @override
  String get posd277bd4a7f37 => 'Amount received is less than the bill total';

  @override
  String get pos66f0e8d0b410 => 'Down payment cannot exceed the PO total';

  @override
  String get posc5ddad284953 => 'Agreed down payment';

  @override
  String get pos0d4e86dd43ca => 'Edit';

  @override
  String get posd43b81387c11 => 'Change Password';

  @override
  String get pos3d05b10abd07 => 'Edit Stock Transfer';

  @override
  String get pos527c4c661da3 => 'Edit Order';

  @override
  String get posda4b035f456f => 'Edit unit price';

  @override
  String get pos7f6115f597fe => 'Edit quantity';

  @override
  String get posa456981f7a35 => 'Change the search term or add a new customer.';

  @override
  String get pos8613138ac9a1 =>
      'Make changes through Store Stock to record them in history.';

  @override
  String get pos32dbeededecf =>
      'Change the search or filters. Products linked to the store appear here.';

  @override
  String get pos652095d719e1 => 'Test link';

  @override
  String get posa2a346200e44 =>
      'Test the link before posting the QR code. Orders enter the active order list with Web Order as the source.';

  @override
  String get posa8ae0ebfbce4 => 'Default Font Size';

  @override
  String get pos83b7dea60a55 => 'Photo size must not exceed 5 MB';

  @override
  String get posea509388c129 => 'Label size';

  @override
  String get posd33b85a37b70 => 'Retry Journal Entry';

  @override
  String get pos469ce4c9a28e => 'Retry Cancellation Journal';

  @override
  String get posc17999007f8f => 'Retry Reversal Journal Entry';

  @override
  String get pos5d6ca5be4503 => 'Repeat PIN';

  @override
  String get pos43ccf0129156 => 'Retry Request';

  @override
  String get pos7c91c6ac823e => 'Repeat guide';

  @override
  String get pos451eaa755c4a => 'Retry previous receipt?';

  @override
  String get pos2dd33eb6ed9e => 'General';

  @override
  String get posec5aab0a9179 => 'Download sample receipt';

  @override
  String get pos8abd3947a6b5 =>
      'Download the sample PDF receipt, open it, and print from the browser. Use the Android app for direct Bluetooth thermal printing.';

  @override
  String get poscfb8fb243b03 => 'Sample receipt download cancelled';

  @override
  String get pos06c6280b7765 =>
      'Unique within the organization; may be entered manually if needed.';

  @override
  String get pos485487d4970f => 'For kitchen';

  @override
  String pos6c74f030d8e7(String arg1) {
    return 'For kitchen: $arg1';
  }

  @override
  String get pos073d6c9f55fe =>
      'For prepared menu items or services using materials/parts. Bundles may include BOM-based products or other bundles; final stock usage is calculated from base components. Component masters are managed in Inventory Web.';

  @override
  String get posde3e49bd421c =>
      'For small purchases paid immediately. No PO shipment, Vendor Bill, or payable is created.';

  @override
  String get pos0693a068e967 => 'Proof upload failed';

  @override
  String get pos8d10c2a32c62 => 'Image upload failed';

  @override
  String posb6b3d93e8479(String arg1) {
    return 'Image upload failed (HTTP $arg1)';
  }

  @override
  String pos5851f7728c66(String arg1) {
    return 'Image upload failed: server response is not JSON (HTTP $arg1).';
  }

  @override
  String get pos6d1570c0ed5d => 'Pro forma upload failed';

  @override
  String get pos9f3f4e0c0a0e => 'Sort';

  @override
  String get pos84c29015de33 => 'Username';

  @override
  String get pos6d07eb268e23 => 'Username and password are required';

  @override
  String get pos3da4232cad38 => 'Username must be at least 3 characters';

  @override
  String get pos45585ce95883 => 'This username is already in use';

  @override
  String get posc07288f18f36 => 'Supervisor username';

  @override
  String get pos84d4cc20900b => 'Username is required';

  @override
  String pos50e3560c32e9(String arg1, String arg2) {
    return 'Suggested addition: $arg1 $arg2.';
  }

  @override
  String get posde8e2428407a => 'Main';

  @override
  String get pos2cf8b197f95e => 'Inventory Validation';

  @override
  String get pos107f6ed46940 => 'Verify & submit';

  @override
  String get pos48c0247cf3ea => 'Verify CAPTCHA';

  @override
  String get pos8257b6733f00 =>
      'Verify the original cashier PIN online, then resend. The transaction remains saved.';

  @override
  String get pos8d47558d0279 => 'PIN verification unavailable';

  @override
  String get pos5d2d9be54cec => 'Verify access';

  @override
  String get posb5ddbecb5231 => 'Verification requires a reachable server.';

  @override
  String get pos784445614b66 => 'Verify cashier & resend';

  @override
  String get pos975be95dacf4 => 'Verify original cashier';

  @override
  String posd42481239233(String arg1) {
    return 'Database migration verification failed at $arg1';
  }

  @override
  String get pose7a82ec760dd => 'Operator verification unavailable';

  @override
  String get pos136300f9a6ad => 'Verify balance details';

  @override
  String get posfdaebba5fc2b => 'Virtual account';

  @override
  String get pos207c7c00630b => 'Void';

  @override
  String pos759eb33e6286(String arg1) {
    return 'Voucher removed. New total $arg1. Review before payment.';
  }

  @override
  String get pos0364b523c94d => 'Could not remove voucher from order';

  @override
  String pos05d7f4d6cf47(String arg1) {
    return 'Voucher $arg1 will be removed. The server recalculates the bill total; review it before payment.';
  }

  @override
  String get posa30d29c8e996 => 'Required for the current Inventory profile';

  @override
  String get pos76fed7f3609a => 'Required if physical stock differs';

  @override
  String get pos25ef7a11e45f => 'Customer required';

  @override
  String get posdc4ec62efd33 =>
      'Required for stock transfers between store warehouse ↔ display.';

  @override
  String get pos3f286ad44bb9 => 'Opening Time';

  @override
  String pos13585ecae7e3(String arg1) {
    return 'Opening time: $arg1';
  }

  @override
  String get pos020f9b28d77a => 'Closing Time';

  @override
  String get pos94677c75fcb8 => 'Opening time unavailable';

  @override
  String get posa427df535276 => 'Order time';

  @override
  String posee16580f1d1c(String arg1) {
    return 'Time: $arg1';
  }

  @override
  String get pos801d866beb88 => 'Walk-in';

  @override
  String get pos298dff72dae2 => 'Warehouse';

  @override
  String get posc8d47c42e360 => 'Warehouses & Locations';

  @override
  String get pos3a0176226d44 => 'Warehouse / Location';

  @override
  String get posfd070731ed26 => 'Warehouse deleted';

  @override
  String get pos21919b3b14a8 => 'Warehouse saved';

  @override
  String get pos7d0fb7463dbb => 'Could not delete warehouse';

  @override
  String get pos0fe60734a6b2 => 'Could not save warehouse';

  @override
  String get pos4fb835991e0f => 'Other warehouses';

  @override
  String get posea1d1795b37d => 'Theme Color';

  @override
  String get pos7ec8ab3a21d5 =>
      'Web Order currently accepts payment at the cashier only; online payments are not available yet.';

  @override
  String get posb336fc558722 => 'WhatsApp';

  @override
  String get pos6348c32e9fc3 => 'WhatsApp as text';

  @override
  String get pos6ff911097025 => 'Local Wi-Fi';

  @override
  String get pos24f6e9a93620 =>
      'Could not open local Wi-Fi. Check your network and retry.';

  @override
  String get pos5754555ecb84 => 'YYYY-MM-DD · follows the posting period';

  @override
  String get pos5976ced22c37 => 'Yes, Receive Goods';

  @override
  String get pose62854369199 => 'advanced';

  @override
  String posadd23ff79c19(String arg1) {
    return 'actual $arg1';
  }

  @override
  String get posa402cc68ed18 => 'reason';

  @override
  String get pos17a3c6b44960 => 'source';

  @override
  String get pos0f35190a786a => 'or with email';

  @override
  String get pos0580e7127940 => 'unpaid';

  @override
  String get pos871d3d68cecb => 'unpaid';

  @override
  String get pos7809dc360252 => 'not recorded';

  @override
  String get pos1be297298b78 => 'unconfirmed';

  @override
  String get pos5cb3a7b4ddf4 => 'notes';

  @override
  String get pos70a7b0d23590 => 'from';

  @override
  String get posd7343a231e9b => 'description';

  @override
  String get pos3afeff377f69 => 'required';

  @override
  String get pos9c018701d0bc => 'applied';

  @override
  String get pos0f3c832976ae => 'draft awaiting validation';

  @override
  String get pos06a45e5495d8 => 'expired';

  @override
  String get pos0deab2a2cfaf => 'quarantine';

  @override
  String get pos15d5e1d3b948 => 'to';

  @override
  String get posce54c69ffee9 => 'expired';

  @override
  String get posd34c12c7afd1 => 'laundry';

  @override
  String get pos9c8096bb4cbc => 'location';

  @override
  String get pos572e26c8af54 => 'selected location';

  @override
  String get pos93fc709f3a3e => 'paid';

  @override
  String get pos646fd2f63975 => 're-enter PIN';

  @override
  String get pos6039de4af239 => 'method';

  @override
  String get pos6c570c44d115 => 'name@email.com (optional)';

  @override
  String get pos586d61286110 => 'amount';

  @override
  String get pos13da303cf88e => 'another outlet';

  @override
  String get pos597a445e77ec => 'customer';

  @override
  String get posb5afb0866405 => 'walk-in customer';

  @override
  String get pos9cd64c607065 => 'receiving';

  @override
  String get posa41af4fbe47d => 'user not found or inactive';

  @override
  String get pos90ec6f7cafce => 'order';

  @override
  String get posd26df9c6abb4 => 'restaurant';

  @override
  String get pos076a81586916 => 'discrepancy';

  @override
  String get posa3ac48246ec3 => 'invalid user session or organization';

  @override
  String get posb269cdf44c06 => 'session revoked';

  @override
  String get pose4ca2609b3c5 => 'stock';

  @override
  String get poscf9d3898c3c2 => 'already closed';

  @override
  String get pos75eaedaa3415 => 'expired';

  @override
  String get pos5be6b7bc380d => 'expired';

  @override
  String get pos1a5cfe31e47d => 'no expiry date';

  @override
  String get pos289ad2a10489 => 'phone';

  @override
  String get pos65e336e20c50 => 'credit';

  @override
  String get pos73185e3fd124 => 'installment';

  @override
  String get posbe1b2f30c1a8 => 'saved';

  @override
  String get pos5a6b85302cab => 'not required';

  @override
  String get pos879feb73384a => 'not found';

  @override
  String get pos7b1221e5f7a8 => 'invalid';

  @override
  String get pos12156b361980 => 'action';

  @override
  String get pos67e6ea635235 => 'store';

  @override
  String get pos6cf4f5f27a49 => 'transaction';

  @override
  String get posf7eaba5d8bf4 => 'destination';

  @override
  String get pos369f683b79e5 => 'amount received';

  @override
  String get pos0df9eea0bad5 => 'unit';

  @override
  String get pos0992d001463f => 'user not found';

  @override
  String pos4fb0953658c9(String arg1) {
    return 'user …$arg1';
  }

  @override
  String get pos4a35c0647dfb => 'warehouse';

  @override
  String posf8d9cba5e651(String arg1) {
    return '$arg1\n\nTransactions are automatically recorded under the cashier who opened the active shift.';
  }

  @override
  String pos36e433c66faa(String arg1, String arg2) {
    return '$arg1\nDue: $arg2';
  }

  @override
  String pos4865be94ff66(String arg1) {
    return '$arg1\nIf the result is uncertain, reload the document before retrying.';
  }

  @override
  String posb682cdaf8e17(String arg1) {
    return '$arg1\nIf disconnected, check the list before creating a new transfer.';
  }

  @override
  String poseca045b64da0(String arg1) {
    return '$arg1\nReload status before retrying if disconnected.';
  }

  @override
  String pos9a3af49b041e(String arg1, String arg2, String arg3) {
    return '$arg1\nAvailable balance $arg2 $arg3';
  }

  @override
  String posf7f7c59d6a0a(String arg1, String arg2, String arg3, String arg4) {
    return '$arg1\n$arg2 $arg3 × Rp $arg4';
  }

  @override
  String posb572718edb66(String arg1) {
    return '$arg1 (default)';
  }

  @override
  String pos05de1a67c3af(String arg1) {
    return '$arg1 The latest data is still shown.';
  }

  @override
  String pos3c0064b85206(String arg1) {
    return '$arg1 The draft remains saved; stock/cash is unchanged.';
  }

  @override
  String posf286f4675572(String arg1) {
    return '$arg1 Days';
  }

  @override
  String posce59266da29b(String arg1) {
    return '$arg1 Check the physical result before retrying.';
  }

  @override
  String pos784f6f055869(String arg1) {
    return '$arg1 active batches';
  }

  @override
  String pos3a95104b1217(String arg1) {
    return '$arg1 recorded batches';
  }

  @override
  String pos9074e3322f20(String arg1, String arg2) {
    return '$arg1 of $arg2';
  }

  @override
  String pos078a5eb9fa64(String arg1, String arg2) {
    return '$arg1 of $arg2 lines processed • check each item\'s remainder';
  }

  @override
  String posf627ed309787(String arg1, String arg2) {
    return '$arg1 of $arg2 steps complete';
  }

  @override
  String pos8270fbc798d5(String arg1) {
    return '$arg1 removed from cart';
  }

  @override
  String posa6d0a58ea7de(String arg1) {
    return '$arg1 selected';
  }

  @override
  String pos2f1e6a806cc7(String arg1) {
    return '$arg1 added';
  }

  @override
  String pos602c13c1eeea(String arg1) {
    return '$arg1 added to cart';
  }

  @override
  String pos5e64822cb742(String arg1) {
    return '$arg1 received';
  }

  @override
  String posc9d3ba9c4543(String arg1) {
    return '$arg1 can only be deleted if no outlet uses it and it has no inventory balance.';
  }

  @override
  String pos07ffbaeefbeb(String arg1) {
    return '$arg1 days';
  }

  @override
  String pos8d46fa4132ae(String arg1) {
    return '$arg1 days recorded';
  }

  @override
  String posc96f7e9303ef(String arg1, String arg2) {
    return '$arg1 days $arg2 hours';
  }

  @override
  String pos0b3c91d7acb1(String arg1) {
    return '$arg1 physical results';
  }

  @override
  String pos89bd7b74615c(String arg1) {
    return '$arg1 item';
  }

  @override
  String posf6026f00f33e(String arg1, String arg2) {
    return '$arg1 item · $arg2';
  }

  @override
  String posc7eeba1af189(String arg1, String arg2) {
    return '$arg1 item • $arg2';
  }

  @override
  String poscc814c436aaa(String arg1) {
    return '$arg1 hours';
  }

  @override
  String posa6aae0f32863(String arg1, String arg2) {
    return '$arg1 hours $arg2 minutes';
  }

  @override
  String posd3db39ddbb57(String arg1) {
    return '$arg1 item types';
  }

  @override
  String posb77962af8721(String arg1, String arg2, String arg3) {
    return '$arg1 item types will increase stock at $arg2.\n\n$arg3\n\nCheck that quantities, batches, and locations are correct.';
  }

  @override
  String pos005ed817deab(String arg1, String arg2) {
    return '$arg1 remaining item types · $arg2';
  }

  @override
  String pos77cc5f06183a(String arg1, String arg2) {
    return '$arg1 item types · $arg2';
  }

  @override
  String pos2b5b18eb7e33(String arg1) {
    return '$arg1 net loss';
  }

  @override
  String pos96c96d35cf4e(String arg1, String arg2) {
    return '$arg1 kg · $arg2';
  }

  @override
  String posd8b7f9fcbdae(String arg1) {
    return '$arg1 components selected';
  }

  @override
  String posc92e889b21e0(String arg1) {
    return '$arg1 seats';
  }

  @override
  String pos2e58e983605b(String arg1, String arg2) {
    return '$arg1 local #$arg2';
  }

  @override
  String poscd596d982fc7(String arg1) {
    return '$arg1 locations';
  }

  @override
  String pos3ddbca1be993(String arg1, String arg2, String arg3, String arg4) {
    return '$arg1 still has $arg2 $arg3 on unreceived POs. $arg4 Review existing POs before creating a new order.';
  }

  @override
  String posc0c6484282fd(String arg1) {
    return '$arg1 minutes';
  }

  @override
  String pos1903b0face48(String arg1) {
    return '$arg1 min';
  }

  @override
  String posa8b15dbf49a2(String arg1) {
    return '$arg1 operators in this period';
  }

  @override
  String posc1d0cd74f8ec(String arg1) {
    return '$arg1 saved orders';
  }

  @override
  String poscda259d82b9a(String arg1) {
    return '$arg1 products are out of stock or at their reorder point.';
  }

  @override
  String pos9511cddc9569(String arg1) {
    return '$arg1 products/services ready for sale.';
  }

  @override
  String pos7d4d5958fa9e(String arg1, String arg2) {
    return '$arg1 location balances • $arg2 item types';
  }

  @override
  String posef655d18b036(String arg1) {
    return '$arg1 system stock';
  }

  @override
  String pos4f29bd492330(String arg1) {
    return '$arg1 already used';
  }

  @override
  String pos9e2b35272c32(String arg1, String arg2) {
    return '$arg1 guests$arg2';
  }

  @override
  String pos67fdbcba215b(String arg1) {
    return '$arg1 sold';
  }

  @override
  String pose9a226455937(String arg1) {
    return '$arg1 available';
  }

  @override
  String pos0137b35ee82f(String arg1) {
    return '$arg1 unavailable';
  }

  @override
  String pos1c13a6636001(String arg1) {
    return '$arg1 active stores linked to sales locations.';
  }

  @override
  String pos30453377460d(String arg1) {
    return '$arg1 total quantity';
  }

  @override
  String pos3badc0263682(String arg1) {
    return '$arg1 transactions';
  }

  @override
  String posb9af015b5b3c(String arg1, String arg2, String arg3) {
    return '$arg1 unfinished transactions$arg2$arg3';
  }

  @override
  String posac37abdf6133(String arg1) {
    return '$arg1 transactions selected';
  }

  @override
  String pose215c398e32f(String arg1) {
    return '$arg1 rejected transactions returned to the queue';
  }

  @override
  String pos2b8d8622ab16(String arg1) {
    return '$arg1 local transactions are not fully synced. Tap to view the queue and conflicts.';
  }

  @override
  String pos452e3bc76740(String arg1) {
    return '$arg1 offline sales transactions are incomplete. Data remains on this device, but sync is deferred until this organization\'s account signs in again.';
  }

  @override
  String pos509814bee562(String arg1) {
    return '$arg1 offline sales transactions are incomplete. Data remains on this device, but cannot sync until this organization\'s account signs in again.';
  }

  @override
  String posc86080cde078(String arg1, String arg2) {
    return '$arg1 transactions · Average $arg2';
  }

  @override
  String pos971fbc291672(String arg1) {
    return '$arg1 txns';
  }

  @override
  String pos256020cc43aa(String arg1, String arg2) {
    return '$arg1 unit · $arg2';
  }

  @override
  String pos83c794c3c247(String arg1) {
    return '$arg1 is required and must not exceed 10 MB';
  }

  @override
  String pose02d08abae0b(String arg1) {
    return '$arg1 active warehouses/sales locations available.';
  }

  @override
  String pos5dfc7705f747(String arg1, String arg2, String arg3) {
    return '$arg1 $arg2 of $arg3 labels sent. Check the physical output before retrying; the last batch may already be printed.';
  }

  @override
  String pos8e2e32f18621(String arg1, String arg2) {
    return '$arg1 $arg2 available';
  }

  @override
  String posb4fb1c3b1411(String arg1) {
    return '$arg1 · Try again';
  }

  @override
  String pos0bdde42d626d(String arg1, String arg2) {
    return '$arg1 · Stock $arg2';
  }

  @override
  String pos2f893bcc6344(String arg1, String arg2, String arg3) {
    return '$arg1 · remaining $arg2 $arg3';
  }

  @override
  String posd4d98a649594(String arg1, String arg2) {
    return '$arg1 · $arg2 invoice';
  }

  @override
  String posdf24f5ec1143(String arg1, String arg2) {
    return '$arg1 · $arg2 item';
  }

  @override
  String posa6e5135e1c96(String arg1, String arg2) {
    return '$arg1 · $arg2 products';
  }

  @override
  String pos6e9f8acab9e7(String arg1, String arg2) {
    return '$arg1 · $arg2. Confirm the number, then select or add a customer at payment.';
  }

  @override
  String posd94b4f688664(String arg1, String arg2, String arg3) {
    return '$arg1 • System $arg2 $arg3';
  }

  @override
  String pos41d9f9c2727c(String arg1, String arg2) {
    return '$arg1 • Stock $arg2';
  }

  @override
  String posd3e4f6b9f3d9(String arg1, String arg2, String arg3) {
    return '$arg1 • Stock $arg2 $arg3';
  }

  @override
  String posbc5439bf7220(String arg1, String arg2) {
    return '$arg1 • $arg2 available';
  }

  @override
  String pos984dd212a7c5(String arg1) {
    return '$arg1% received';
  }

  @override
  String pos69b46e44cb84(String arg1) {
    return '$arg1. Data is not a live update.';
  }

  @override
  String pos5a750eacdedd(String arg1) {
    return '${arg1}The document will be approved to continue inventory processing.';
  }

  @override
  String pos4aff662939ed(String arg1) {
    return '${arg1}The document will be rejected and must be corrected before reprocessing.';
  }

  @override
  String pos60620fd8af23(String arg1) {
    return '${arg1}The PO will be submitted for approval. Check the purchase value and destination.';
  }

  @override
  String pos3b16fedb59a0(String arg1, String arg2) {
    return '${arg1}h ${arg2}m';
  }

  @override
  String posecae7016438c(String arg1, String arg2, String arg3, String arg4) {
    return '$arg1$arg2\n${arg3}Lost $arg4';
  }

  @override
  String posdf19d6c3808e(String arg1, String arg2) {
    return '$arg1$arg2 discrepancy';
  }

  @override
  String pos04f490437f3e(String arg1, String arg2, String arg3, String arg4) {
    return '• $arg1: $arg2 $arg3 · Cost Rp $arg4';
  }

  @override
  String get receiptCustomerLabel => 'Customer';

  @override
  String get stockMovementIn => 'Stock In';

  @override
  String get stockMovementOut => 'Stock Out';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'Use device language';

  @override
  String get languageSaveFailed =>
      'Language preference could not be saved. Try again.';

  @override
  String get pushPermissionDenied =>
      'Device notifications are disabled. Enable them in Android settings.';

  @override
  String get pushConnectionError =>
      'Device notifications are not connected yet. Try refreshing.';

  @override
  String get signInAction => 'Sign In';

  @override
  String get reportPreviousPeriod => 'Compared with previous period';

  @override
  String get reportAverageTransaction => 'Average value per transaction';

  @override
  String get reportTopProductQuantity =>
      'Items sold from the top products list';

  @override
  String get dashboardCatalogProducts => 'Products available in the catalog';

  @override
  String get financialProfitLoss => 'Profit & Loss';

  @override
  String get financialReportSubtitle => 'Posted income and expenses';

  @override
  String get financialScope => 'All businesses in this organization';

  @override
  String get financialScopeNote =>
      'Combines all stores and branches, not only the active store.';

  @override
  String get financialBasisNote =>
      'This report uses posted journals. Unrecorded expenses or transactions are not included.';

  @override
  String get financialCostNote =>
      'Cost of sales follows historical journal costs, not current catalog purchase prices. Complete recording of all business expenses cannot be verified automatically.';

  @override
  String get financialNetSales => 'Net Sales';

  @override
  String get financialCogs => 'Cost of Sales';

  @override
  String get financialGrossProfit => 'Recorded Gross Profit';

  @override
  String get financialNetProfit => 'Recorded Net Profit / Loss';

  @override
  String get financialRecorded => 'Based on posted journals';

  @override
  String get financialUnavailable => 'Not available yet';

  @override
  String get financialDetails => 'Account Breakdown';

  @override
  String get financialOperatingExpenses => 'Operating Expenses';

  @override
  String get financialOtherRevenue => 'Other Income';

  @override
  String get financialOtherExpenses => 'Other Expenses';

  @override
  String get financialUnclassifiedRevenue => 'Unclassified Income';

  @override
  String get financialUnclassifiedExpenses => 'Unclassified Expenses';

  @override
  String get financialTotalRevenue => 'Total Recorded Income';

  @override
  String get financialTotalExpenses => 'Total Recorded Expenses';

  @override
  String get financialReview => 'Data needs review';

  @override
  String get financialNoEntries => 'No posted journals in this period.';

  @override
  String get financialDenied => 'Financial report access is not available';

  @override
  String get financialDeniedNote =>
      'Ask an administrator for Finance report access. Sales report access does not automatically include organization-wide profit and loss.';

  @override
  String get financialFailed => 'Report could not be loaded';

  @override
  String get financialFailedNote =>
      'Check your connection and try again. Previous data is not displayed as a current report.';

  @override
  String get financialRetry => 'Try Again';

  @override
  String get financialRefresh => 'Refresh Report';

  @override
  String get financialPeriod => 'Report Period';

  @override
  String get financialToday => 'Today';

  @override
  String get financialSevenDays => 'Last 7 Days';

  @override
  String get financialThisMonth => 'This Month';

  @override
  String get financialLastMonth => 'Last Month';

  @override
  String get financialCustomPeriod => 'Choose Date Range';

  @override
  String get financialInvalidRange =>
      'Choose a period of up to 366 days ending no later than today.';

  @override
  String get financialUpdated => 'Updated';

  @override
  String get financialMissingMapping =>
      'Some accounts are unclassified or missing. Review account classification in Finance.';

  @override
  String get financialMissingCogs =>
      'Cost of sales accounts are not configured. Cost of sales and gross profit cannot be confirmed.';

  @override
  String get financialUnpostedSales => 'POS sales not yet posted';

  @override
  String get financialUnpostedReturns => 'POS returns not yet posted';

  @override
  String get financialDraftJournals => 'Draft journals';

  @override
  String get financialUnpostedCogs =>
      'Transactions with historical costs have no posted cost journal in this period';

  @override
  String get financialHeaderPosting =>
      'Some journals post directly to a header account. Review the source journals.';

  @override
  String get financialUnknownIssue =>
      'Some data limitations need review in Finance.';

  @override
  String get financialLedgerDenied =>
      'Journal details require Finance general ledger access.';

  @override
  String get financialLedger => 'Journal Entries';

  @override
  String get financialPrevious => 'Previous';

  @override
  String get financialNext => 'Next';

  @override
  String get financialDebit => 'Debit';

  @override
  String get financialCredit => 'Credit';

  @override
  String get financialCogsMismatch =>
      'Posted cost journal differs from the historical transaction cost';

  @override
  String get financialSessionChanged => 'Report session or access changed';

  @override
  String get financialSessionNote =>
      'Reload the report using your active session. Previous session data has been cleared.';

  @override
  String get businessCashFlow => 'Cash Flow';

  @override
  String get businessAging => 'Receivables & Payables';

  @override
  String get businessReceivables => 'Customer Receivables';

  @override
  String get businessPayables => 'Supplier Payables';

  @override
  String get businessInventory => 'Inventory';

  @override
  String get businessMovement => 'Stock Movements';

  @override
  String get businessRestock => 'Restock Needs';

  @override
  String get businessCutoff => 'As of Date';

  @override
  String get businessRange => 'Movement Period';

  @override
  String get businessSearch => 'Search reference or name';

  @override
  String get businessAllSources => 'All Supported Sources';

  @override
  String get businessPosSources => 'POS Invoices Only';

  @override
  String get businessSources => 'Invoice Source';

  @override
  String get businessOpeningCash => 'Opening Cash';

  @override
  String get businessCashIn => 'Cash In';

  @override
  String get businessCashOut => 'Cash Out';

  @override
  String get businessClosingCash => 'Closing Cash';

  @override
  String get businessCashChange => 'Net Cash Change';

  @override
  String get businessOutstanding => 'Outstanding';

  @override
  String get businessOverdue => 'Overdue';

  @override
  String get businessNotDue => 'Not Yet Due';

  @override
  String get businessUnknownDue => 'Due Date Unknown';

  @override
  String get businessOpenDocuments => 'Open Documents';

  @override
  String get businessExcludedDocuments => 'Excluded Sources';

  @override
  String get businessStockValue => 'Inventory Value';

  @override
  String get businessBookValue => 'Inventory Ledger Balance';

  @override
  String get businessDifference => 'Inventory Difference';

  @override
  String get businessProductsEvidence => 'Products with Evidence';

  @override
  String get businessOpeningStockValue => 'Opening Inventory Value';

  @override
  String get businessClosingStockValue => 'Closing Inventory Value';

  @override
  String get businessStockValueChange => 'Inventory Value Change';

  @override
  String get businessStockProducts => 'Stock Products';

  @override
  String get businessLowStock => 'Low Stock';

  @override
  String get businessOutOfStock => 'Out of Stock';

  @override
  String get businessReorderProducts => 'Needs Restocking';

  @override
  String get businessReference => 'Reference';

  @override
  String get businessParty => 'Customer / Supplier';

  @override
  String get businessDate => 'Date';

  @override
  String get businessDueDate => 'Due Date';

  @override
  String get businessBucket => 'Aging Bucket';

  @override
  String get businessAmount => 'Document Amount';

  @override
  String get businessPaid => 'Payments at Cutoff';

  @override
  String get businessCredited => 'Credits / Returns at Cutoff';

  @override
  String get businessName => 'Product Name';

  @override
  String get businessAccount => 'Account';

  @override
  String get businessQuantity => 'Quantity';

  @override
  String get businessValue => 'Value';

  @override
  String get businessStatus => 'Evidence Status';

  @override
  String get businessUnit => 'Base Unit';

  @override
  String get businessMinimum => 'Minimum Level';

  @override
  String get businessReorder => 'Reorder Point';

  @override
  String get businessOpeningQuantity => 'Opening Quantity';

  @override
  String get businessIncoming => 'Stock In';

  @override
  String get businessOutgoing => 'Stock Out';

  @override
  String get businessAdjustment => 'Adjustment';

  @override
  String get businessOtherMovement => 'Other Changes';

  @override
  String get businessClosingQuantity => 'Closing Quantity';

  @override
  String get businessDescription => 'Description';

  @override
  String get businessActivity => 'Activity';

  @override
  String get businessOperating => 'Operating';

  @override
  String get businessInvesting => 'Investing';

  @override
  String get businessFinancing => 'Financing';

  @override
  String get businessUnclassified => 'Unclassified';

  @override
  String get businessCurrent => 'Not Yet Due';

  @override
  String get businessDays30 => '1–30 Days Overdue';

  @override
  String get businessDays60 => '31–60 Days Overdue';

  @override
  String get businessDays90 => '61–90 Days Overdue';

  @override
  String get businessDaysMore90 => 'Over 90 Days Overdue';

  @override
  String get businessComplete => 'Checked Evidence Complete';

  @override
  String get businessPartial => 'Some Sources Are Incomplete';

  @override
  String get businessUnknown => 'Evidence Is Not Yet Verified';

  @override
  String get businessDiscrepancy => 'Difference Needs Review';

  @override
  String get businessEmpty =>
      'No details match the filter. Also review the source coverage notes.';

  @override
  String get businessDetails => 'Report Details';

  @override
  String get businessSourceNotes => 'Source and Coverage Notes';

  @override
  String get businessPage => 'Page';

  @override
  String get businessRows => 'rows';

  @override
  String get businessDenied =>
      'This report requires Finance and source permissions. Historical inventory requires journal access; combined restocking requires all-location access.';

  @override
  String get businessCashMissing =>
      'Cash/bank accounts are not mapped. Balances are not assumed to be zero.';

  @override
  String get businessGrossAmbiguous =>
      'Some combined journals cannot be separated into gross receipts and payments. Net balances still follow the ledger.';

  @override
  String get businessAgingBasis =>
      'Outstanding amounts and payments are reconstructed through the cutoff date, not taken from today’s balances.';

  @override
  String get businessAgingExclusions =>
      'Totals include only reconstructable sources. Excluded records are listed in the source notes.';

  @override
  String get businessPosOnly =>
      'Only invoices originating from POS transactions; unpaid orders are not automatically Finance receivables.';

  @override
  String get businessTradeAR =>
      'Customer receivables from supported sources, not every company receivable asset.';

  @override
  String get businessTradeAP =>
      'Supported supplier trade payables; loans, payroll liabilities and taxes are excluded.';

  @override
  String get businessHistoricalStock =>
      'Inventory balances and values follow historical evidence across all locations, not current catalog prices.';

  @override
  String get businessStockMissing =>
      'The baseline or evidence chain is incomplete. Current stock is not substituted for historical balances.';

  @override
  String get businessMovementBasis =>
      'Per-product quantities use base units. Opening + in − out + adjustments + other changes = closing.';

  @override
  String get businessMovementMissing =>
      'Gross movements require a shared baseline and a verified event chain throughout the period. Separate cutoff snapshots alone do not prove all movements.';

  @override
  String get businessRestockLive =>
      'Restock needs use today’s stock and current minimum/reorder thresholds; this is not a historical report.';

  @override
  String get businessExport => 'Export Report';

  @override
  String get businessCsv => 'CSV / Excel';

  @override
  String get businessPdf => 'PDF';

  @override
  String get businessExportChanged =>
      'Data changed. Refresh the report before exporting so all rows are consistent.';

  @override
  String get businessExportLimit =>
      'Export is too large. Narrow the period or search.';

  @override
  String get businessExportFailed =>
      'Export failed. Refresh the report and try again.';

  @override
  String get businessPdfGlyph =>
      'PDF does not support some characters in this data. Use CSV to preserve all names.';

  @override
  String get businessExportScope => 'Scope';

  @override
  String get businessExportCurrency => 'Currency';

  @override
  String get businessExportCoverage => 'Evidence Coverage';

  @override
  String get businessExportAllRows =>
      'Export includes every page for this filter.';

  @override
  String get businessWithheld => 'Tax Withheld';

  @override
  String get businessCashReconciliation => 'Cash Reconciliation Difference';

  @override
  String get businessOpenSource => 'Open current document';

  @override
  String get businessSourceFailed =>
      'The source document could not be opened. Check access and try again.';

  @override
  String get posPreparingSales => 'Preparing sales...';

  @override
  String get posCashierNavigationShortcuts =>
      'Alt+1 / Alt+2 Cashier · Alt+3 Catalog';

  @override
  String get tradeTitle => 'Payables & Receivables';

  @override
  String get tradeCreate => 'Record Manual Bill';

  @override
  String get tradeNewBill => 'New bill';

  @override
  String get tradeOpening => 'Unrecorded opening balance';

  @override
  String get tradeManualNote =>
      'For monetary bills without stock or tax lines. Do not re-enter an invoice already recorded in Finance.';

  @override
  String get tradeOpeningNote =>
      'Only balances never recorded in Finance. Opening balances use equity and do not become new income or expenses.';

  @override
  String get tradeCustomer => 'Customer name';

  @override
  String get tradeSupplier => 'Supplier name';

  @override
  String get tradeExistingCustomer => 'Existing customer (optional)';

  @override
  String get tradeNewCustomer => 'Use customer name';

  @override
  String get tradeControl => 'Bill account';

  @override
  String get tradeCounter => 'Entry category';

  @override
  String get tradeSave => 'Save Bill';

  @override
  String get tradePay => 'Record Payment';

  @override
  String get tradeReceive => 'Record Receipt';

  @override
  String get tradePaymentNote =>
      'Online entry to Finance accounts. This is not a new sale and does not change the shift cash drawer.';

  @override
  String get tradeCash => 'Cash — Finance account';

  @override
  String get tradeTransfer => 'Bank transfer';

  @override
  String get tradeCashAccount => 'Receipt cash account';

  @override
  String get tradeBank => 'Bank account';

  @override
  String get tradePending => 'Unconfirmed request';

  @override
  String get tradePendingNote =>
      'Do not create a replacement entry or payment. Confirm again using the same request.';

  @override
  String get tradeRetrySame => 'Confirm again';

  @override
  String get tradeCreateSuccess => 'Bill and journal recorded.';

  @override
  String get tradePaySuccess => 'Payment and journal recorded.';

  @override
  String get tradeDetails => 'Bill details';

  @override
  String get tradeHistory => 'Payment history';

  @override
  String get tradeNoHistory => 'No payments yet.';

  @override
  String get tradeLastHistory => 'Showing up to the latest 50 payments.';

  @override
  String get tradeConfirm => 'Confirm entry';

  @override
  String get tradeConfirmNote =>
      'Check the party, amount, date and category. This action posts a journal and updates Finance balances.';

  @override
  String get tradeCancel => 'Cancel';

  @override
  String get tradeContinue => 'Yes, record';

  @override
  String get tradeRequired => 'Required.';

  @override
  String get tradeInvalidAmount =>
      'Enter a positive whole Rupiah amount within the outstanding balance.';

  @override
  String get tradeInvalidDate => 'Invalid date or due date.';

  @override
  String get tradeNoAccounts =>
      'Account categories are unavailable. Configure Finance account mappings first.';

  @override
  String get tradeSettled => 'Include settled bills';

  @override
  String get tradeSearch => 'Search party or document number';

  @override
  String get tradeNoAccess =>
      'Payables/receivables access is unavailable for this user.';

  @override
  String get tradePOSScope =>
      'Only POS receivables for permitted stores. Manual entries require tenant-wide Finance access.';

  @override
  String get tradeProof => 'Recorded payment';

  @override
  String get tradeJournal => 'Journal number';

  @override
  String get tradeUnverified => 'Journal evidence could not be verified.';

  @override
  String get tradeNotes => 'Notes (optional)';

  @override
  String get tradeSavedCustomer => 'Selected customer';

  @override
  String get tradeUnknown =>
      'The result is not confirmed. Confirm again using the same request.';

  @override
  String get setupSalesGuideTitle => 'Start selling guide';

  @override
  String get setupSalesGuideHelp =>
      'Optional. Add products or services; other settings can wait.';

  @override
  String get setupSalesGuideView => 'View guide';

  @override
  String get setupSalesGuideHide => 'Hide guide';

  @override
  String get inventoryOpeningStockLabel => 'Opening stock';

  @override
  String get serviceDirectLabel => 'Direct service';

  @override
  String get serviceReservationEndOptional => 'Reservation end (optional)';

  @override
  String get serviceReservationDefaultDuration =>
      'The reservation defaults to two hours unless changed.';

  @override
  String get serviceItemOrNotesRequired =>
      'Enter the service item or job notes.';

  @override
  String get serviceCartQuantityHelp =>
      'Weight and quantity come from the cart. No need to enter them again.';

  @override
  String get serviceCloseObjectDetails => 'Close individual item details';

  @override
  String get serviceObjectDetailsOptional =>
      'Individual item details (optional)';

  @override
  String get serviceObjectWeight => 'Item weight (kg)';

  @override
  String get serviceObjectQuantity => 'Item quantity';

  @override
  String get serviceObjectTag => 'Item ID / tag';

  @override
  String get serviceObjectNotes => 'Item notes';

  @override
  String get serviceSplitOneItem => 'Split off one item';

  @override
  String get serviceRemoveObjectDetails => 'Remove these item details';

  @override
  String pinIncorrectAttemptsRemaining(String count) {
    return 'Incorrect PIN. $count attempts remaining.';
  }

  @override
  String secretShow(String field) {
    return 'Show $field';
  }

  @override
  String get googleSignInIncomplete =>
      'Google sign-in was canceled or did not finish. If you already selected an account, try again or use your email and password.';

  @override
  String get googleSignInConfigurationError =>
      'Google sign-in is not configured correctly for this app version. Use your email and password for now and contact Pantoo support.';

  @override
  String get checkoutRecoveryReference => 'Payment reference';

  @override
  String get orderPaymentUnconfirmed =>
      'The order payment has not been confirmed. Check the same order or contact an administrator; do not collect a second payment.';

  @override
  String get checkoutInvalidFreshData =>
      'Payment data is not valid yet. Check the cart and payment amounts, then try again. The payment has not been sent.';

  @override
  String get checkoutRecoveryConnection =>
      'Could not connect to the server while recovering the payment. The payment record is still saved; try again when the server is reachable. Do not pay again.';

  @override
  String get checkoutRecoveryUnconfirmed =>
      'The server could not confirm the payment result. Contact an administrator with this payment reference; do not create a replacement payment.';

  @override
  String get checkoutRecoveryResponse =>
      'The server response does not match the payment record. Contact an administrator with this payment reference; do not pay again.';

  @override
  String secretHide(String field) {
    return 'Hide $field';
  }
}
