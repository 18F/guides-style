$(function() {
  $('.sidebar-nav').each(function() {
    accordion($(this));
  });

  // https://github.com/18F/private-eye#usage
  PrivateEye({
    defaultMessage: "This link is private to 18F.",
    ignoreUrls: [
      'https://18f.slack.com',
      'https://docs.google.com',
      'https://drive.google.com',
      'https://github.com/18F/Accessibility_Reviews',
      'https://github.com/18F/blog-drafts',
      'https://github.com/18F/codereviews',
      'https://github.com/18F/DevOps',
      'https://github.com/18F/handbook',
      'https://github.com/18F/Infrastructure',
      'https://github.com/18F/staffing-and-resources',
      'https://github.com/18F/team-api.18f.gov',
      'https://github.com/18F/writing-lab',
      'https://gsa.my.salesforce.com',
      'https://insite.gsa.gov'
    ]
  });
});
