import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../data/models/e_ticket_models.dart';

class ETicketPdfGenerator {
  static Future<File> generateETicket(ETicketData ticket) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    ticket.airline.isEmpty ? 'E-TICKET' : ticket.airline,
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor(0.0, 0.35, 0.7),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey, width: 1),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'E-TICKET',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor(0.96, 0.96, 0.96),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColor(0.85, 0.85, 0.85)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Passenger',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          ticket.passengerName,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'PNR',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          ticket.pnr,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor(0.0, 0.35, 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              if (ticket.ticketNumber.isNotEmpty) ...[
                pw.Row(
                  children: [
                    pw.Text(
                      'Ticket Number: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(ticket.ticketNumber),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text(
                      'Issue Date: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(ticket.issueDate),
                  ],
                ),
                pw.SizedBox(height: 24),
              ],
              pw.Text(
                'Itinerary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor(0.0, 0.35, 0.7),
                ),
              ),
              pw.SizedBox(height: 12),
              ...ticket.segments.map((segment) {
                return pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 16),
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor(0.85, 0.85, 0.85)),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            segment.airline?.isNotEmpty == true
                                ? segment.airline!
                                : ticket.airline,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (segment.ticketNumber.isNotEmpty)
                            pw.Text(
                              segment.ticketNumber,
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColor(0.0, 0.35, 0.7),
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _segmentCell(segment.origin, 'From'),
                          pw.Text('→', style: pw.TextStyle(fontSize: 24)),
                          _segmentCell(segment.destination, 'To'),
                        ],
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _segmentCell(segment.departureTime, 'Departure'),
                          _segmentCell(segment.arrivalTime, 'Arrival'),
                          if (segment.flightClass != null)
                            _segmentCell(segment.flightClass!, 'Class'),
                          if (segment.gate != null)
                            _segmentCell(segment.gate!, 'Gate'),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              pw.SizedBox(height: 24),
              if (ticket.totalAmount != null && ticket.currency != null)
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor(0.0, 0.35, 0.7),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Paid',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                        ),
                      ),
                      pw.Text(
                        '${ticket.currency} ${ticket.totalAmount!.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              pw.SizedBox(height: 32),
              pw.Center(
                child: pw.Text(
                  'This is an electronic ticket. Please present a valid photo ID at the airport.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    return await _writeToFile(bytes, 'eticket_${ticket.pnr}.pdf');
  }

  static pw.Widget _segmentCell(String value, String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static Future<File> _writeToFile(Uint8List bytes, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> openFile(File file) async {
    await OpenFilex.open(file.path);
  }
}
