import {
  Paper,
  TextField,
  Button,
  Stack,
  MenuItem,
  Radio,
  RadioGroup,
  FormControlLabel,
  FormControl,
  FormLabel,
  Alert,
  Typography,
  Box
} from "@mui/material";
import { useState } from "react";

const cities = [
  "Delhi",
  "Mumbai",
  "Bangalore",
  "Chennai",
  "Kolkata",
  "Hyderabad",
  "Pune",
  "Ahmedabad",
  "Jaipur",
  "Lucknow"
];

export default function OrderForm() {
  const [deliveryCity, setDeliveryCity] = useState("Delhi");
  const [recipientName, setRecipientName] = useState("");
  const [recipientAddress, setRecipientAddress] = useState("");
  const [pinCode, setPinCode] = useState("");
  const [mobilePhone, setMobilePhone] = useState("");
  const [deliveryDate, setDeliveryDate] = useState("");
  const [deliveryTime, setDeliveryTime] = useState("daytime");
  const [cardMessage, setCardMessage] = useState("");
  const [messageOnCake, setMessageOnCake] = useState("");
  const [specialInstruction, setSpecialInstruction] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    const orderData = {
      deliveryCity,
      recipientName,
      recipientAddress,
      pinCode,
      mobilePhone,
      deliveryDate,
      deliveryTime,
      cardMessage,
      messageOnCake,
      specialInstruction
    };
    
    console.log("Order submitted:", orderData);
    // TODO: Implement API call to submit order
    alert("Order submitted successfully!");
  };

  return (
    <Paper sx={{ p: 4, maxWidth: 900, mx: "auto", mt: 3 }}>
      <Alert severity="warning" sx={{ mb: 3 }}>
        Please do not use special characters in order form eg. $ & • › % ^
      </Alert>

      <form onSubmit={handleSubmit}>
        <Stack spacing={3}>
          {/* Delivery City */}
          <Box>
            <Typography variant="body2" sx={{ mb: 1, fontWeight: 500 }}>
              Delivery City <span style={{ color: "red" }}>*</span>
            </Typography>
            <TextField
              select
              fullWidth
              required
              value={deliveryCity}
              onChange={(e) => setDeliveryCity(e.target.value)}
            >
              {cities.map((city) => (
                <MenuItem key={city} value={city}>
                  {city}
                </MenuItem>
              ))}
            </TextField>
          </Box>

          {/* Recipient Name */}
          <Box>
            <Typography variant="body2" sx={{ mb: 1, fontWeight: 500 }}>
              Recipient Name <span style={{ color: "red" }}>*</span>
            </Typography>
            <TextField
              fullWidth
              required
              value={recipientName}
              onChange={(e) => setRecipientName(e.target.value)}
            />
          </Box>

          {/* Recipient Address */}
          <Box>
            <Typography variant="body2" sx={{ mb: 1, fontWeight: 500 }}>
              Recipient Address <span style={{ color: "red" }}>*</span>
            </Typography>
            <TextField
              fullWidth
              required
              multiline
              rows={3}
              value={recipientAddress}
              onChange={(e) => setRecipientAddress(e.target.value)}
            />
          </Box>

          {/* Pin Code */}
          <Box>
            <Typography variant="body2" sx={{ mb: 1, fontWeight: 500 }}>
              Pin Code <span style={{ color: "red" }}>*</span>
            </Typography>
            <TextField
              fullWidth
              required
              value={pinCode}
              onChange={(e) => setPinCode(e.target.value)}
              inputProps={{ maxLength: 6 }}
            />
          </Box>

          {/* Country */}
          <Box>
            <Typography variant="body2" sx={{ mb: 1, fontWeight: 500 }}>
              Country <span style={{ color: "red" }}>*</span>
            </Typography>
            <Typography variant="body1" sx={{ fontWeight: 600 }}>
              INDIA (We deliver only within India)
            </Typography>
          </Box>

          {/* Mobile/Phone No. */}
          <Box>
            <Typography variant="body2" sx={{ mb: 1, fontWeight: 500 }}>
              Mobile/Phone No. <span style={{ color: "red" }}>*</span>
            </Typography>
            <TextField
              fullWidth
              required
              value={mobilePhone}
              onChange={(e) => setMobilePhone(e.target.value)}
              inputProps={{ maxLength: 10 }}
            />
          </Box>

          {/* Delivery Time Section */}
          <Box sx={{ bgcolor: "#f5f5f5", p: 3, borderRadius: 1 }}>
            <Typography
              variant="h6"
              sx={{ color: "#e91e63", mb: 2, fontWeight: 600 }}
            >
              Delivery Time
            </Typography>

            {/* Delivery Date */}
            <Box sx={{ mb: 2 }}>
              <Typography variant="body2" sx={{ mb: 1, fontWeight: 500 }}>
                Delivery Date <span style={{ color: "red" }}>*</span>
              </Typography>
              <TextField
                fullWidth
                required
                type="date"
                value={deliveryDate}
                onChange={(e) => setDeliveryDate(e.target.value)}
                InputLabelProps={{ shrink: true }}
                placeholder="MM/DD/YYYY"
              />
            </Box>

            {/* Delivery Time Options */}
            <Box>
              <Typography variant="body2" sx={{ mb: 1, fontWeight: 500 }}>
                Delivery Time <span style={{ color: "red" }}>*</span>
              </Typography>
              <FormControl component="fieldset">
                <RadioGroup
                  value={deliveryTime}
                  onChange={(e) => setDeliveryTime(e.target.value)}
                >
                  <FormControlLabel
                    value="daytime"
                    control={<Radio />}
                    label="Any Time Between 10AM to 9PM FREE"
                  />
                  <FormControlLabel
                    value="midnight"
                    control={<Radio />}
                    label="MIDNIGHT DELIVERY FROM 10PM to 12.30AM Rs. 250/($4)"
                  />
                </RadioGroup>
              </FormControl>

              <Alert severity="error" sx={{ mt: 2 }}>
                <Typography variant="body2">
                  <strong>For Midnight orders please confirm availability before placing orders on +91-9212125612, 9971060931</strong>
                  {" . For Midnight delivery if the occasion is on 15th Dec, then select 14th Dec as Delivery date."}
                </Typography>
              </Alert>
            </Box>
          </Box>

          {/* Card Message */}
          <Box>
            <Typography variant="body2" sx={{ mb: 1, fontWeight: 500 }}>
              Card Message <span style={{ color: "red" }}>*</span>
            </Typography>
            <TextField
              fullWidth
              required
              multiline
              rows={3}
              value={cardMessage}
              onChange={(e) => setCardMessage(e.target.value)}
            />
          </Box>

          {/* Message On Cake */}
          <Box>
            <Typography variant="body2" sx={{ mb: 1, fontWeight: 500 }}>
              Message On Cake
            </Typography>
            <TextField
              fullWidth
              multiline
              rows={3}
              value={messageOnCake}
              onChange={(e) => setMessageOnCake(e.target.value)}
            />
          </Box>

          {/* Special Instruction */}
          <Box>
            <Typography variant="body2" sx={{ mb: 1, fontWeight: 500 }}>
              Special Instruction
            </Typography>
            <TextField
              fullWidth
              multiline
              rows={3}
              value={specialInstruction}
              onChange={(e) => setSpecialInstruction(e.target.value)}
            />
          </Box>

          {/* Submit Button */}
          <Box sx={{ display: "flex", justifyContent: "flex-end", mt: 3 }}>
            <Button
              type="submit"
              variant="contained"
              size="large"
              sx={{ minWidth: 200 }}
            >
              Submit Order
            </Button>
          </Box>
        </Stack>
      </form>
    </Paper>
  );
}
