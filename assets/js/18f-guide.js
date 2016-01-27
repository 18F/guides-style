$(function() {
  $('.sidebar-nav').each(function() {
    accordion($(this));
  });

  // https://github.com/18F/private-eye#usage
  PrivateEye({
    ignoreUrls: [
      'https://docs.google.com',
      'https://drive.google.com',
      'https://github.com/18F/Accessibility_Reviews',
      'https://github.com/18F/DevOps',
      'https://github.com/18F/handbook',
      'https://github.com/18F/writing-lab'
    ]
  });
});
