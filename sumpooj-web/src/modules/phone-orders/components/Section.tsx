import React from "react";
import { Box, Typography } from "@mui/material";

interface Props {
  title: string;
  children: React.ReactNode;
}

function Section({ title, children }: Props) {
  return (
    <Box sx={{ mb: 4 }}>
      <Typography
        variant="h6"
        sx={{
          mb: 2,
          fontWeight: 600,
        }}
      >
        {title}
      </Typography>

      {children}
    </Box>
  );
}

export default Section;