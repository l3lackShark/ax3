package ax3;

import ax3.TypedTree;
import ax3.filters.*;

class Filters {
	public static function run(context:Context, tree:TypedTree) {
		var externImports = new ExternModuleLevelImports(context);
		for (f in [
			externImports,
			new InlineStaticConsts(context),
			new RewriteE4X(context),
			new RewriteSwitch(context),
			new RestArgs(context),
			new RewriteRegexLiterals(context),
			new HandleNew(context),
			new AddSuperCtorCall(context),
			new RewriteBlockBinops(context),
			new RewriteNewArray(context),
			new RewriteDelete(context),
			new RewriteArrayAccess(context),
			new RewriteIs(context),
			new RewriteCFor(context),
			new RewriteForEach(context),
			new RewriteForIn(context),
			new RewriteHasOwnProperty(context),
			new CoerceToBool(context),
			new RewriteNonBoolOr(context),
			new NumberToInt(context),
			new InvertNegatedEquality(context),
			new HaxeProperties(context),
			new UnqualifiedSuperStatics(context),
			// new AddParens(context),
			new AddRequiredParens(context),
			// new CheckExpectedTypes(context)
			new ArrayApi(context),
			new StringApi(context),
			new NumberApi(context),
			new FunctionApply(context),
			new ToString(context),
			new NamespacedToPublic(context),
		]) {
			f.run(tree);
		}

		sys.io.File.saveContent("OUT/Globals.hx", externImports.printGlobalsClass());
	}
}
