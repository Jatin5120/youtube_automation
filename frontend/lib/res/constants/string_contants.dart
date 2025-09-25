class AppStrings {
  const AppStrings._();

  static const String timeoutError =
      'Oops! The request took too long to process. Please check your internet connection and try again. If the issue persists, you can contact our support team for assistance.';

  static const String somethingWentWrong = 'Oops! Something went wrong. Please try again after some time.';

  static const String socketProblem = 'There has been a problem with your connectivity. Please check your internet connection and try again.';

  static const String noInternet = 'No internet connection. Please connect to the internet and try again.';
}

class AppPrompts {
  const AppPrompts._();

  static String titlePrompt(String title) =>
      '''You are a business development expert analyzing YouTube video titles for potential collaboration opportunities.

VIDEO TITLE: "$title"

TASK: Extract a specific, relevant business insight or theme that directly relates to this video's content and would be valuable for reaching out to this creator.

ANALYSIS GUIDELINES:
- Focus on the SPECIFIC topic, trend, or angle mentioned in the title
- Identify unique keywords, concepts, or themes from the actual title
- Consider what specific business value or partnership opportunity this video represents
- Think about the creator's specific expertise or audience interest shown in this title
- Make it relevant to the actual content, not just a generic category

OUTPUT FORMAT:
- Provide exactly 2-4 words that capture the SPECIFIC theme from this title
- Use only letters and spaces (no numbers, symbols, or special characters)
- Make it specific to the video content, not generic
- Focus on the unique aspect or angle of this particular video

EXAMPLES:
- "How to Build a 10M SaaS Business in 2024" becomes "SaaS Scaling"
- "iPhone 15 Pro Max Camera Test vs Samsung" becomes "Mobile Photography"
- "10 Minute Morning Workout for Busy Professionals" becomes "Professional Fitness"
- "Digital Marketing Trends That Actually Work in 2024" becomes "Marketing Trends"
- "Why I Quit My 9-5 to Start a YouTube Channel" becomes "Career Transition"
- "Building a 1M E-commerce Store in 6 Months" becomes "E-commerce Growth"

RESPONSE:''';

  static String namePrompt(String name, String channel, String description) =>
      '''You are an expert at extracting personal names from YouTube channel information for professional email outreach.

CHANNEL INFORMATION:
- Username: $name
- Channel Name: $channel
- Description: $description

TASK: Find the real name of the channel owner/creator that can be used in a professional email greeting.

EXTRACTION RULES:
1. Look for actual personal names in the description, channel name, or username
2. Prioritize first names over full names
3. Ignore brand names, company names, or generic terms
4. Look for patterns like "Hi, I'm [Name]", "My name is [Name]", "[Name] here", etc.
5. Check if the username contains a real name
6. Consider if the channel name contains a personal name

OUTPUT RULES:
- If you find a clear personal name: Return just the first name
- If no personal name is found: Return "Team $channel"
- Use only letters and spaces (no special characters)
- Keep it professional and appropriate for email greetings

EXAMPLES:
- "Hi, I'm John Smith" → "John"
- "Welcome to Sarah's Kitchen" → "Sarah" 
- "TechReviewer123" → "Team $channel"
- "My name is Alex" → "Alex"

RESPONSE:''';
}
