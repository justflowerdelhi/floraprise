import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/repositories/order_repository.dart';
import '../../managers/business_settings_manager.dart';
import '../../models/crm_models.dart';
import '../../models/order_workspace_models.dart';
import '../../models/walk_in_session.dart';
import 'pdf_bill_builder.dart';
import 'pdf_delivery_slip_builder.dart';
import 'pdf_download_helper.dart';
import 'pdf_quotation_builder.dart';

/// Central Service for generating, downloading, and sharing Bill, Delivery Slip & Quotation PDFs.
class PdfDocumentService {
  PdfDocumentService({
    BusinessSettingsManager? businessSettingsManager,
    PdfBillBuilder? billBuilder,
    PdfDeliverySlipBuilder? deliverySlipBuilder,
    PdfQuotationBuilder? quotationBuilder,
  })  : _businessSettingsManager = businessSettingsManager ?? BusinessSettingsManager(),
        _billBuilder = billBuilder ?? const PdfBillBuilder(),
        _deliverySlipBuilder = deliverySlipBuilder ?? const PdfDeliverySlipBuilder(),
        _quotationBuilder = quotationBuilder ?? const PdfQuotationBuilder();

  final BusinessSettingsManager _businessSettingsManager;
  final PdfBillBuilder _billBuilder;
  final PdfDeliverySlipBuilder _deliverySlipBuilder;
  final PdfQuotationBuilder _quotationBuilder;

  /// Generates Bill PDF bytes from strongly typed order models.
  Future<Uint8List> generateBillPdf({
    required OrderDetailHeader header,
    OrderDetailBundle? bundle,
    BusinessSettings? business,
  }) async {
    final settings = business ?? await _businessSettingsManager.load();
    return _billBuilder.build(
      business: settings,
      header: header,
      bundle: bundle,
    );
  }

  /// Generates Bill PDF bytes from a payload map.
  Future<Uint8List> generateBillPdfFromPayload(
    Map<String, dynamic> payload, {
    BusinessSettings? business,
  }) async {
    final settings = business ?? await _businessSettingsManager.load();
    return _billBuilder.buildFromPayload(payload, business: settings);
  }

  /// Generates Delivery Slip PDF bytes from strongly typed order models.
  Future<Uint8List> generateDeliverySlipPdf({
    required OrderDetailHeader header,
    OrderDetailBundle? bundle,
    BusinessSettings? business,
  }) async {
    final settings = business ?? await _businessSettingsManager.load();
    return _deliverySlipBuilder.build(
      business: settings,
      header: header,
      bundle: bundle,
    );
  }

  /// Generates Delivery Slip PDF bytes from a payload map.
  Future<Uint8List> generateDeliverySlipPdfFromPayload(
    Map<String, dynamic> payload, {
    BusinessSettings? business,
  }) async {
    final settings = business ?? await _businessSettingsManager.load();
    return _deliverySlipBuilder.buildFromPayload(payload, business: settings);
  }

  /// Generates and triggers download (Web) or share sheet (Mobile/Desktop) for a Bill PDF.
  Future<void> downloadOrShareBillPdf({
    required BuildContext context,
    required OrderDetailHeader header,
    OrderDetailBundle? bundle,
  }) async {
    try {
      final bytes = await generateBillPdf(header: header, bundle: bundle);
      final sanitizedOrderNo = header.displayOrderNo.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final fileName = 'Bill-$sanitizedOrderNo.pdf';

      await saveOrDownloadPdf(
        bytes: bytes,
        fileName: fileName,
        shareTitle: 'Bill ${header.displayOrderNo}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bill PDF generated ($fileName)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate Bill PDF: $e')),
        );
      }
    }
  }

  /// Generates and triggers download (Web) or share sheet (Mobile/Desktop) for a Delivery Slip PDF.
  Future<void> downloadOrShareDeliverySlipPdf({
    required BuildContext context,
    required OrderDetailHeader header,
    OrderDetailBundle? bundle,
  }) async {
    try {
      final bytes = await generateDeliverySlipPdf(header: header, bundle: bundle);
      final sanitizedOrderNo = header.displayOrderNo.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final fileName = 'DeliverySlip-$sanitizedOrderNo.pdf';

      await saveOrDownloadPdf(
        bytes: bytes,
        fileName: fileName,
        shareTitle: 'Delivery Slip ${header.displayOrderNo}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delivery Slip PDF generated ($fileName)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate Delivery Slip PDF: $e')),
        );
      }
    }
  }

  /// Generates and triggers download (Web) or share sheet from POS payload.
  Future<void> downloadOrShareBillPdfFromPayload({
    required BuildContext context,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final bytes = await generateBillPdfFromPayload(payload);
      final rawNo = (payload['order_no'] ?? payload['invoiceNumber'] ?? 'WALK_IN').toString();
      final sanitizedNo = rawNo.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final fileName = 'Bill-$sanitizedNo.pdf';

      await saveOrDownloadPdf(
        bytes: bytes,
        fileName: fileName,
        shareTitle: 'Bill $rawNo',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bill PDF generated ($fileName)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate Bill PDF: $e')),
        );
      }
    }
  }

  /// Generates and triggers download (Web) or share sheet from POS delivery payload.
  Future<void> downloadOrShareDeliverySlipPdfFromPayload({
    required BuildContext context,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final bytes = await generateDeliverySlipPdfFromPayload(payload);
      final rawNo = (payload['order_no'] ?? payload['orderNo'] ?? 'DELIVERY').toString();
      final sanitizedNo = rawNo.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final fileName = 'DeliverySlip-$sanitizedNo.pdf';

      await saveOrDownloadPdf(
        bytes: bytes,
        fileName: fileName,
        shareTitle: 'Delivery Slip $rawNo',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delivery Slip PDF generated ($fileName)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate Delivery Slip PDF: $e')),
        );
      }
    }
  }

  /// Generates Quotation PDF bytes from CRM Enquiry, WalkInSession, and OrderTotals.
  Future<Uint8List> generateQuotationPdf({
    required CrmEnquiryItem enquiry,
    required WalkInSession session,
    required OrderTotals totals,
    BusinessSettings? business,
    DateTime? quotationDate,
    DateTime? validUntilDate,
  }) async {
    final settings = business ?? await _businessSettingsManager.load();
    return _quotationBuilder.build(
      business: settings,
      enquiry: enquiry,
      session: session,
      totals: totals,
      quotationDate: quotationDate,
      validUntilDate: validUntilDate,
    );
  }

  /// Generates and triggers download (Web) or native share sheet (Mobile/Desktop) for a Quotation PDF.
  Future<void> downloadOrShareQuotationPdf({
    required BuildContext context,
    required CrmEnquiryItem enquiry,
    required WalkInSession session,
    required OrderTotals totals,
    DateTime? quotationDate,
    DateTime? validUntilDate,
  }) async {
    try {
      final bytes = await generateQuotationPdf(
        enquiry: enquiry,
        session: session,
        totals: totals,
        quotationDate: quotationDate,
        validUntilDate: validUntilDate,
      );
      final refNo = session.draftOrderId != null
          ? 'QUO-${session.draftOrderId}'
          : 'QUO-${enquiry.customerName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')}';
      final fileName = '$refNo.pdf';

      await saveOrDownloadPdf(
        bytes: bytes,
        fileName: fileName,
        shareTitle: 'Quotation $refNo for ${enquiry.customerName}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quotation PDF generated ($fileName)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate Quotation PDF: $e')),
        );
      }
    }
  }
}
