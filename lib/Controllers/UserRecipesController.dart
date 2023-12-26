import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:recipe_widget/Models/recipesRepo.dart';
import '../Models/DefaultIngredientsRepo.dart';
import '../Models/instructionsRepo.dart';
import '../constantVariables/Constant.dart';
import 'UserIngredientsController.dart';



class UserRecipesController extends ChangeNotifier {
  List<recipesRepo> Recipes = [];
  List<DefaultIngredientsRepo> ingredients = [];
  List<String> ingredientsID = [];
  List<instructionsRepo> insrtuctions = [];
  int currentStep = 0;
  recipesRepo? Recipe;
  final _firestore = FirebaseFirestore.instance;

  void addStep() {
    if (currentStep < (insrtuctions.length - 1)) {
      currentStep++;
    }
    notifyListeners();
  }

  void backStep() {
    if (currentStep >= 1) {
      currentStep--;
    }
    notifyListeners();
  }

  void restartStep() {
    currentStep = 0;
    notifyListeners();
  }

  Future<void> getRecipes(String? userID) async {
    Recipes = [];
    if (userID != null) {
      final responce = await _firestore
          .collection("UserRecipes")
          .doc(userID)
          .collection("Recipe List")
          .get();
      Future.forEach(responce.docs, (Recipe) async {
        await getIngredients(Recipe.id);
        await getInsrtuctions(userID, Recipe.id);
        reorganizeInstructions();

        Recipes.add(recipesRepo.fromJson(
            Recipe.id, Recipe.data(), ingredients, insrtuctions));
        notifyListeners();
      });
    }
  }

  Future<void> getIngredients(String RecipeID) async {
    ingredients = [];
    ingredientsID = [];
    final responce = await _firestore
        .collection("UserRecipes")
        .doc(kUserId)
        .collection("Recipe List")
        .doc(RecipeID)
        .collection("Ingredients")
        .get();
    Future.forEach(responce.docs, (Ingredient) async {
      ingredientsID.add(Ingredient.id);
      final responced = await UserIngredientController()
          .getIngredientById(kUserId, Ingredient.data()["Link"]);
      ingredients.add(responced);
      notifyListeners();
    });
  }

  Future<void> getSingleRecipe(String? userID, String RecipeID) async {
    ingredients = [];
    ingredientsID = [];
    if (userID != null) {
      final responce = await _firestore
          .collection("UserRecipes")
          .doc(kUserId)
          .collection("Recipe List")
          .doc(RecipeID)
          .get();
      await getIngredients(RecipeID);
      await getInsrtuctions(kUserId, RecipeID);
      reorganizeInstructions();
      Recipe = recipesRepo.fromJson(
          responce.id, responce.data()!, ingredients, insrtuctions);
    }
    notifyListeners();
  }

  Future<void> getInsrtuctions(String? userID, String RecipeID) async {
    insrtuctions = [];
    if (userID != null) {
      final responce = await _firestore
          .collection("UserRecipes")
          .doc(userID)
          .collection("Recipe List")
          .doc(RecipeID)
          .collection("Instructions")
          .get();
      for (var instruction in responce.docs) {
          insrtuctions.add(
              instructionsRepo.fromJson(instruction.id, instruction.data()));
        }
    }
  }

  void reorganizeInstructions() {
    insrtuctions.sort((a, b) => a.Step.compareTo(b.Step));
  }

  Future<void> DeleteRecipe(RecipeID) async {
    final responce = await _firestore
        .collection("UserRecipes")
        .doc(kUserId)
        .collection("Recipe List")
        .doc(RecipeID)
        .get();

    responce.reference.delete();
  }

  Future<String> AddRecipe(String name, String Category, String nutrition,
      String Time, String Servings, String image,String videoUrl,String category) async {
    final responce = await _firestore
        .collection("UserRecipes")
        .doc(kUserId)
        .collection("Recipe List")
        .add({
      "Name": name,
      "nutrition": nutrition,
      "Time": Time,
      "Servings": Servings,
      "Category": Category,
      "Image": image,
      "VideoUrl":videoUrl,
      "category":category
    });
    return responce.id.toString();
  }

  Future<void> EditRecipe(String name, String nutrition,
      String Time, String Servings, String image,String videoUrl, String category ) async {
    Recipe!.recipe_name = name;
    Recipe!.nutrition = nutrition;
    Recipe!.time = Time;
    Recipe!.Servings = Servings;
    Recipe!.Image = image;
    final responce = await _firestore
        .collection("UserRecipes")
        .doc(kUserId)
        .collection("Recipe List")
        .doc(Recipe!.ID)
        .update({
      "recipe_name": name,
      "nutrition": nutrition,
      "Time": Time,
      "Servings": Servings,
      "Image": image,
      "VideoUrl":videoUrl,
       "category":category
    });
  }

  Future<QuerySnapshot> QueryCategoryRecipe(String Category) async {
    return await FirebaseFirestore.instance
        .collection("UserRecipes")
        .doc(kUserId)
        .collection("Recipe List")
        .where("Category", isEqualTo: Category)
        .get();
  }

  Future<void> FilterCategory(String Category) async {
    Recipes = [];
    QuerySnapshot snapshot = await QueryCategoryRecipe(Category);
    if (snapshot.docs.isNotEmpty) {
      Recipes += snapshot.docs.map((e) {
        return recipesRepo.fromJson(
            e.id, e.data() as Map<String, dynamic>, [], []);
      }).toList();
    }
    notifyListeners();
  }
 }

//Ingredient.data()["Link"])