Pod::Spec.new do |s|
  s.name             = "PullToDismissTransition"
  s.version          = "0.7.0"
  s.homepage         = "https://github.com/benguild/PullToDismissTransition"
  s.summary          = "(Beta) Uses `UIPercentDrivenInteractiveTransition` and `UIViewControllerAnimatedTransitioning` to quickly implement nice "pull-to-dismiss" interactions on modal view controller(s). — Also handles `UIScrollView` bounce toggling dynamically when necessary."
  s.license          = 'MIT'
  s.author           = { "Ben Guild" => "hello@benguild.com" }
  s.source           = { :git => "https://github.com/benguild/PullToDismissTransition.git", :tag => s.version.to_s }
  s.source_files     = 'PullToDismissTransition.swift', 'PullToDismissable.swift'
  s.social_media_url = 'https://twitter.com/benguild'

  s.platform     = :ios, '10.0'
  s.requires_arc = true

end
