package dk.sdu.mmmi.validation

import dk.sdu.mmmi.typescriptdsl.And
import dk.sdu.mmmi.typescriptdsl.Attribute
import dk.sdu.mmmi.typescriptdsl.CompareConstraint
import dk.sdu.mmmi.typescriptdsl.Constraint
import dk.sdu.mmmi.typescriptdsl.Div
import dk.sdu.mmmi.typescriptdsl.Expression
import dk.sdu.mmmi.typescriptdsl.Field
import dk.sdu.mmmi.typescriptdsl.Minus
import dk.sdu.mmmi.typescriptdsl.Mult
import dk.sdu.mmmi.typescriptdsl.Or
import dk.sdu.mmmi.typescriptdsl.Parenthesis
import dk.sdu.mmmi.typescriptdsl.Plus
import java.util.List
import org.eclipse.xtext.validation.Check
import dk.sdu.mmmi.typescriptdsl.TypescriptdslPackage
import dk.sdu.mmmi.typescriptdsl.IntType
import dk.sdu.mmmi.typescriptdsl.Table
import dk.sdu.mmmi.typescriptdsl.Parameter
import org.eclipse.xtext.EcoreUtil2
import dk.sdu.mmmi.typescriptdsl.Query
import dk.sdu.mmmi.typescriptdsl.RegexConstraint
import dk.sdu.mmmi.typescriptdsl.StringExp
import java.util.ArrayList
import java.util.Collections
import java.util.jar.Attributes
import dk.sdu.mmmi.typescriptdsl.StringType
import dk.sdu.mmmi.typescriptdsl.DateType

class ConstraintValidator extends AbstractTypescriptdslValidator {
	
	@Check
	def validateField(Field field) {
		val q = EcoreUtil2.getContainerOfType(field, Query)
		if (q === null) {
			if (!(field.attr.type instanceof IntType)) 
			error('''Attribute «field.attr.name» is not of type int''', TypescriptdslPackage.Literals.FIELD__ATTR)	
		}
				
	}
	
	@Check
	def validateOperatorsOnlyHoldsNumbers(Expression exp) {
		switch exp {
			Plus: { 
				if (exp.left instanceof StringExp) {
					error('''Operator + can not include strings''', TypescriptdslPackage.Literals.PLUS__LEFT)
				}
				if (exp.right instanceof StringExp) {
					error('''Operator + can not include strings''', TypescriptdslPackage.Literals.PLUS__RIGHT)
				}
			}
			Minus: { 
				if (exp.left instanceof StringExp) {
					error('''Operator - can not include strings''', TypescriptdslPackage.Literals.MINUS__LEFT)
				}
				if (exp.right instanceof StringExp) {
					error('''Operator - can not include strings''', TypescriptdslPackage.Literals.MINUS__RIGHT)
				}
			}
			Mult: { 
				if (exp.left instanceof StringExp) {
					error('''Operator * can not include strings''', TypescriptdslPackage.Literals.MULT__LEFT)
				}
				if (exp.right instanceof StringExp) {
					error('''Operator * can not include strings''', TypescriptdslPackage.Literals.MULT__RIGHT)
				}
			}
			Div: {
				if (exp.left instanceof StringExp) {
					error('''Operator / can not include strings''', TypescriptdslPackage.Literals.DIV__LEFT)
				}
				if (exp.right instanceof StringExp) {
					error('''Operator / can not include strings''', TypescriptdslPackage.Literals.DIV__RIGHT)
				}	 
			}
		}
	}
	

	@Check
	def validateTypeOfAttributeIsTheSameAsTheStaticConstraint(CompareConstraint cons) {
		var type = cons.left as Field
		var vali = cons.right
		if (cons.right instanceof Field) {
			type = cons.right as Field
			vali = cons.left
		}
		if (vali instanceof Parameter) {
			return
		}
		switch type.attr.type {
			IntType: {
				if (vali instanceof StringExp) {
					error('''Attribute «type» is not of type int''', TypescriptdslPackage.Literals.COMPARE_CONSTRAINT__LEFT)
				}
			}
			StringType: {
				if (!(vali instanceof StringExp)) {
					error('''Attribute «type» is not of type String''', TypescriptdslPackage.Literals.COMPARE_CONSTRAINT__RIGHT)
				}
			}
			default: {
				return
			}
		}
	}
	
	@Check
	def validateOnlyOneParameterPerCompareConstraint(Parameter p) {
		val cons = EcoreUtil2.getContainerOfType(p, CompareConstraint)
		var parameters = new ArrayList<String>
		cons.getParametersFromCompareConstraint(parameters)
		if (parameters.size > 1) {
			error('''CompareConstraint cannot contains more than one parameter''', TypescriptdslPackage.Literals.PARAMETER__VALUE)
		}
	}
	
	@Check
	def validateDuplicateParameterNameOnSameQuery(Parameter p) {
		val q = EcoreUtil2.getContainerOfType(p, Query)
		val parameters = getParametersOnQuery(q)
		if (Collections.frequency(parameters, p.value) > 1) {
			error('''Parameter «p.value» is not unique''', TypescriptdslPackage.Literals.PARAMETER__VALUE)
		}		
	}
	
	def getParametersOnQuery(Query q) {
		var cons = new ArrayList<CompareConstraint>
		q.where.extractListOfCompareConstraints(cons)
		var parameters = new ArrayList<String>
		for (CompareConstraint c : cons) {
			c.getParametersFromCompareConstraint(parameters)
		}
		return parameters
	}

	def getParametersFromCompareConstraint(CompareConstraint c, List<String> parameters) {
		c.left.extractParameters(parameters)
		c.right.extractParameters(parameters)
	}
	
	def void extractParameters(Expression exp, List<String> list) {
		switch exp {
			Plus: { exp.left.extractParameters(list); exp.right.extractParameters(list) }
			Minus: { exp.left.extractParameters(list); exp.right.extractParameters(list) }
			Mult: { exp.left.extractParameters(list); exp.right.extractParameters(list) }
			Div: { exp.left.extractParameters(list); exp.right.extractParameters(list) }
			Parenthesis: exp.exp.extractParameters(list)
			Parameter: list.add(exp.value)
		}
	}
	
	@Check
	def validateParameterOnlyOnQuery(Parameter parameter) {
		val q = EcoreUtil2.getContainerOfType(parameter, Query)
		if (q === null) {
			error('''Parameter «parameter.value» can only be used on Query types''', TypescriptdslPackage.Literals.PARAMETER__VALUE)
		}
	}
	
	@Check
	def validateStringExpOnlyOnQuery(StringExp str) {
		val q = EcoreUtil2.getContainerOfType(str, Query)
		if (q === null) {
			error('''StringExp «str.value» can only be used on Query types''', TypescriptdslPackage.Literals.STRING_EXP__VALUE)
		}
	}
	
	@Check
	def validateRegexOnlyOnAttributeConstraint(RegexConstraint regCon) {
		val q = EcoreUtil2.getContainerOfType(regCon, Attribute)
		if (q === null) {
			error('''RegexConstraint «regCon.value» can only be used on Attribute Constraint types''', TypescriptdslPackage.Literals.REGEX_CONSTRAINT__VALUE)
		}
	}
	
	@Check
	def validateConstraint(Attribute attr) {
		val List<CompareConstraint> compares = newArrayList()
		attr.constraint.extractListOfCompareConstraints(compares)
		compares.forEach[
			val list = countFields
			if (!list.exists[exists[it === attr.name]]) {
				error('''Attribute «attr.name» is not used in constraint''', TypescriptdslPackage.Literals.ATTRIBUTE__CONSTRAINT)	
			}
			if (!list.get(0).forall[!list.get(1).contains(it)]) {
				error('Attribute name is the same as on the left side', it, TypescriptdslPackage.Literals.COMPARE_CONSTRAINT__RIGHT)
			}
		]
	}
	
	@Check
	def validatePrimary(Table table) {
		val primaries = table.attributes.filter[it.primary]
		if (primaries.empty) {
			error('''Table «table.name» does not contain a primary key.''', TypescriptdslPackage.Literals.TABLE__NAME)
		}
		
		if (primaries.length > 1) {
			error('''Table «table.name» contains more than one primary key.''', TypescriptdslPackage.Literals.TABLE__NAME)
		}
	}
	
	
	def void extractListOfCompareConstraints(Constraint con, List<CompareConstraint> list) {
		switch con {
			Or: { con.left.extractListOfCompareConstraints(list); con.right.extractListOfCompareConstraints(list) }
			And: { con.left.extractListOfCompareConstraints(list); con.right.extractListOfCompareConstraints(list) }
			CompareConstraint: list.add(con)
		}
	}
	
	def countFields(CompareConstraint con) {
		val List<String> left = newArrayList()
		val List<String> right = newArrayList()
		con.left.extractFields(left)
		con.right.extractFields(right)
		return #[left, right]
	}
	
	def void extractFields(Expression exp, List<String> list) {
		switch exp {
			Plus: { exp.left.extractFields(list); exp.right.extractFields(list) }
			Minus: { exp.left.extractFields(list); exp.right.extractFields(list) }
			Mult: { exp.left.extractFields(list); exp.right.extractFields(list) }
			Div: { exp.left.extractFields(list); exp.right.extractFields(list) }
			Parenthesis: exp.exp.extractFields(list)
			Field: list.add(exp.attr.name)
		}
	}
}