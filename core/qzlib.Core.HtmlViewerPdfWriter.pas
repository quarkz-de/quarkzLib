unit qzLib.Core.HtmlViewerPdfWriter;

interface

uses
  HtmlView;

type
  IHtmlViewerPdfWriter = interface
    ['{4A27F1E9-D166-4543-936B-B52227D5D8EC}']
    procedure SaveToFile(const AFilename: String);
  end;

  THtmlViewerPdfWriter = class(TInterfacedObject, IHtmlViewerPdfWriter)
  private
    FViewer: THtmlViewer;
  public
    constructor Create(const AViewer: THtmlViewer);
    procedure SaveToFile(const AFilename: String);
  end;

implementation

{
  SynPDF
  - https://github.com/synopse/SynPDF

  Original THtml2Pdf on synopse.info:
  - https://synopse.info/fossil/dir?name=HtmlView/htm2pdf
  - https://synopse.info/forum/viewtopic.php?id=56
}

uses
  WinApi.Windows, System.SysUtils, System.Classes, Vcl.Forms,
  Vcl.Graphics, Vcl.Printers,
  SynPdf;

type
  THtml2Pdf = class(TPdfDocument)
  private
    FViewer: THtmlViewer;
    FMarginLeft: Double;
    FMarginTop: Double;
    FMarginRight: Double;
    FMarginBottom: Double;
    FScaleToFit: Boolean;
    FDrawPageNumber: Boolean;
    FDrawPageNumberText: String;
    function Points2Pixels(APoints: Single): Integer;
    function Centimeters2Points(ACentimeters: Double): Single;
    function GetOrientation: TPrinterOrientation;
    procedure SetOrientation(const Value: TPrinterOrientation);
    procedure SetDefaultPaperSize(const Value: TPDFPaperSize);
  public
    property Orientation: TPrinterOrientation read GetOrientation
      write SetOrientation;
    property DefaultPaperSize: TPDFPaperSize write SetDefaultPaperSize;
    property Viewer: THtmlViewer read FViewer write FViewer;
    property MarginLeft: Double read FMarginLeft write FMarginLeft;
    property MarginTop: Double read FMarginTop write FMarginTop;
    property MarginRight: Double read FMarginRight write FMarginRight;
    property MarginBottom: Double read FMarginBottom write FMarginBottom;
    property ScaleToFit: Boolean read FScaleToFit write FScaleToFit;
    property DrawPageNumber: Boolean read FDrawPageNumber write FDrawPageNumber;
    property DrawPageNumberText: String read FDrawPageNumberText write FDrawPageNumberText;
    procedure Execute;
  end;

{$REGION 'THtml2Pdf'}

const
  CPointsPerInch = 72;
  CCentimetersPerInch = 2.54;

function THtml2Pdf.Points2Pixels(APoints: Single): Integer;
begin
  Result := Round(APoints / CPointsPerInch * Screen.PixelsPerInch);
end;

function THtml2Pdf.Centimeters2Points(ACentimeters: Double): Single;
begin
  Result := ACentimeters / CCentimetersPerInch * CPointsPerInch;
end;

procedure THtml2Pdf.SetOrientation(const Value: TPrinterOrientation);
var
  LTmp: Integer;
begin
  if Value <> Orientation then
    begin
      LTmp := DefaultPageWidth;
      DefaultPageWidth := DefaultPageHeight;
      DefaultPageHeight := LTmp;
    end;
end;

function THtml2Pdf.GetOrientation: TPrinterOrientation;
begin
  Result := TPrinterOrientation(Ord(DefaultPageWidth > DefaultPageHeight));
end;

procedure THtml2Pdf.SetDefaultPaperSize(const Value: TPDFPaperSize);
var
  LB: TPrinterOrientation;
begin
  LB := Orientation;
  inherited DefaultPaperSize := Value;
  Orientation := LB;
end;

procedure THtml2Pdf.Execute;
var
  LFormatWidth, LWidth, LHeight, LI: Integer;
  LPages: TList;
  LPage: TMetafile;
  LScale: Single;
  LMarginX, LMarginY, LPointsWidth, LPointsHeight, LMarginBottom: Single;
  PageText: string;
begin
  // ForceJPEGCompression := 80;
  LPointsWidth := DefaultPageWidth - Centimeters2Points(MarginLeft + MarginRight);
  LFormatWidth := Points2Pixels(LPointsWidth);
  LWidth := Viewer.FullDisplaySize(LFormatWidth).cx;

  if ScaleToFit and (LWidth > LFormatWidth) and (LFormatWidth > 0) then
    LScale := LFormatWidth / LWidth
  else
    LScale := 1;

  LPointsHeight := (DefaultPageHeight - Centimeters2Points(MarginTop + MarginBottom)) / LScale;
  LHeight := Points2Pixels(LPointsHeight);
  LPages := Viewer.MakePagedMetaFiles(LWidth, LHeight);
  LMarginX := Centimeters2Points(MarginLeft);
  LMarginY := Centimeters2Points(MarginTop);
  LMarginBottom := Centimeters2Points(MarginBottom);

  for LI := 0 to LPages.Count - 1 do
    begin
      AddPage;
      LPage := TMetafile(LPages[LI]);
      Canvas.GSave;
      Canvas.Rectangle(LMarginX, LMarginBottom, LPointsWidth, LPointsHeight);
      Canvas.Clip; // THtmlView may print out of the margins ;)
      Canvas.RenderMetaFile(LPage, LScale, LScale, LMarginX, LMarginY);
      Canvas.GRestore;

      if DrawPageNumber then
        begin
          if DrawPageNumberText = '' then
            PageText := 'Seite %d/%d'
          else
            PageText := DrawPageNumberText;
          PageText := Format(PageText, [LI + 1, LPages.Count]);
          Canvas.SetFont('Arial', 9, []);
          Canvas.SetRGBStrokeColor(clBlack);
          Canvas.TextOut(LMarginX + (LPointsWidth -
            Canvas.TextWidth(PDFString(PageText))) / 2, LMarginBottom - 9,
            PDFString(PageText));
        end;

      FreeAndNil(LPage);
    end;

  FreeAndNil(LPages);
end;

{$ENDREGION}

{$REGION 'THtmlViewerPdfWriter'}

constructor THtmlViewerPdfWriter.Create(const AViewer: THtmlViewer);
begin
  FViewer := AViewer;
end;

procedure THtmlViewerPdfWriter.SaveToFile(const AFilename: String);
var
  Html2Pdf: THtml2Pdf;
begin
  Html2Pdf := THtml2Pdf.Create;

  Html2Pdf.Viewer := FViewer;

  Html2Pdf.MarginLeft := FViewer.PrintMarginLeft;
  Html2Pdf.MarginTop := FViewer.PrintMarginTop;
  Html2Pdf.MarginRight := FViewer.PrintMarginRight;
  Html2Pdf.MarginBottom := FViewer.PrintMarginBottom;

  Html2Pdf.ScaleToFit := false;
  Html2Pdf.Orientation := poPortrait;
  Html2Pdf.DefaultPaperSize := psA4;
  Html2Pdf.DrawPageNumber := false;
  Html2Pdf.DrawPageNumberText := 'Seite %d/%d';

  Html2Pdf.Execute;
  Html2Pdf.SaveToFile(AFilename);

  Html2Pdf.Free;
end;

{$ENDREGION}

end.
