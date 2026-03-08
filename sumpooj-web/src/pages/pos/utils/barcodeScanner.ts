let buffer = "";
let timer: any = null;

const SCAN_TIMEOUT = 50;

export const startBarcodeScanner = (
  onScan: (barcode: string) => void
) => {

  const handleKey = (e: KeyboardEvent) => {

    if (timer) clearTimeout(timer);

    if (e.key.length === 1) {
      buffer += e.key;
    }

    timer = setTimeout(() => {

      if (buffer.length >= 6) {
        onScan(buffer);
      }

      buffer = "";

    }, SCAN_TIMEOUT);
  };

  window.addEventListener("keydown", handleKey);

  return () => {
    window.removeEventListener("keydown", handleKey);
  };
}