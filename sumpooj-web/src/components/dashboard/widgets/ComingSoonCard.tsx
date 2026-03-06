import { Card, CardContent, Typography } from "@mui/material";
import AddIcon from "@mui/icons-material/Add";

export default function ComingSoonCard() {
  return (
    <Card sx={{ height: "100%", opacity: 0.6 }}>
      <CardContent
        sx={{
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          flexDirection: "column",
          height: "100%"
        }}
      >
        <AddIcon />
        <Typography fontSize={13}>
          Coming Soon
        </Typography>
      </CardContent>
    </Card>
  );
}
