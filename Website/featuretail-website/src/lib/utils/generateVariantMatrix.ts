export type VariantOptionInput = {
  name: string
  values: string[]
}

export type VariantMatrixRow = {
  options: {
    name: string
    value: string
  }[]
}

export function generateVariantMatrix(
  options: VariantOptionInput[]
): VariantMatrixRow[] {

  if (!options.length) return []

  const combine = (
    optionIndex: number,
    current: { name: string; value: string }[]
  ): VariantMatrixRow[] => {

    if (optionIndex === options.length) {
      return [{ options: current }]
    }

    const option = options[optionIndex]
    const rows: VariantMatrixRow[] = []

    for (const value of option.values) {
      rows.push(
        ...combine(optionIndex + 1, [
          ...current,
          { name: option.name, value }
        ])
      )
    }

    return rows
  }

  return combine(0, [])
}