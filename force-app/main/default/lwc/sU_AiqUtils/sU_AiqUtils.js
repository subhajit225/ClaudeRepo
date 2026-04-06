function convertToTimezone(utcDateStr, targetTimeZone) {
  try{
    if (!targetTimeZone || !utcDateStr) {
      console.log("Invalid target time zone or UTC date string.");
      return utcDateStr;
    }
    const utcDate = new Date(utcDateStr);
    if (isNaN(utcDate.getTime())) {
      throw new Error("Invalid UTC date string format.");
    }
    
    const dateOptions = {
      timeZone: targetTimeZone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    };
    const timeOptions = {
      timeZone: targetTimeZone,
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    };

    // Format the date and time separately
    const dateFormatter = new Intl.DateTimeFormat("en-US", dateOptions);
    const timeFormatter = new Intl.DateTimeFormat("en-US", timeOptions);

    // Extract formatted date and time
    const formattedDate = dateFormatter.format(utcDate); // MM/DD/YYYY
    const formattedTime = timeFormatter.format(utcDate); // HH:MM:SS AM/PM

    const [month, day, year] = formattedDate.split("/");
    const [hour, minute, second] = formattedTime.split(/:| /);
    const period = formattedTime.slice(-2); // AM/PM

    // Convert hour to 24-hour
    let hour24 = parseInt(hour, 10);
    if (period === "PM" && hour24 !== 12) {
      hour24 += 12;
    } else if (period === "AM" && hour24 === 12) {
      hour24 = 0;
    }

    const convertedDate = `${year}-${month}-${day}T${hour24.toString().padStart(2, "0")}:${minute}:${second}.${utcDateStr.split(".")[1]}`;
    return convertedDate;
  }catch(err){
    console.error("Error converting date to timezone:", err);
    throw new Error("Failed to convert date to the specified timezone.");
  }
}

function trackEvent(event, userData) {
  const { Name: user_name, Email: user_id } = userData;
  const { feature_category, feature_name, interaction_type, feature_description, metric, uid, caseNumber: case_number } = event;
  let data = {
      user_id,
      user_name,
      feature_category,
      feature_name,
      interaction_type,   
      description: feature_description,
      case_number,
      uid,
      ts: new Date().toISOString().replace('T', ' ').split('.')[0],
      metric
  }
  if(event.generated_response){
    data.generated_response = event.generated_response;
  }
  window.gza('ah_interaction', data);
}


export { convertToTimezone, trackEvent };