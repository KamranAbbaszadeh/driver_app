class IntroductionScreenModel {
  String lottieURL;
  String title;
  String subTitle;

  IntroductionScreenModel({
    required this.lottieURL,
    required this.title,
    required this.subTitle,
  });
}

List<IntroductionScreenModel> screens = [
  IntroductionScreenModel(
      lottieURL: "assets/intro_screen/Animation3.json",
      title: "Some Title",
      subTitle: "Some Long Description of current Page"),
  IntroductionScreenModel(
      lottieURL: "assets/intro_screen/Animation1.json",
      title: "Some Title",
      subTitle: "Some Long Description of current Page"),
  IntroductionScreenModel(
      lottieURL: "assets/intro_screen/Animation4.json",
      title: "Some Title",
      subTitle: "Some Long Description of current Page"),
  IntroductionScreenModel(
      lottieURL: "assets/intro_screen/Animation2.json",
      title: "Some Title",
      subTitle: "Some Long Description of current Page"),
  IntroductionScreenModel(
      lottieURL: "assets/intro_screen/Animation5.json",
      title: "Some Title",
      subTitle: "Some Long Description of current Page"),
];
