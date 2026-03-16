export function generateSKU(base: string, values: string[]) {

  const cleanBase = base
    .replace(/\s+/g, "-")
    .toUpperCase()

  const optionPart = values
    .map(v =>
      v
        .replace(/\s+/g, "-")
        .toUpperCase()
    )
    .join("-")

  return `${cleanBase}-${optionPart}`
}