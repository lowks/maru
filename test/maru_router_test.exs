defmodule Maru.RouterTest do
  use ExUnit.Case, async: true
  alias Maru.Router.Param
  alias Maru.Router.Validator

  test "optional requires group" do
    defmodule OptionalTest do
      use Maru.Router
      params do
        requires :foo, type: :string, regexp: ~r/^[a-z]+$/, desc: "hehe"
        group :group do
          group :group, type: Map do
            optional :bar, type: Integer, range: 1..100
          end
        end
      end
      def pc, do: @param_context
    end

    assert [ %Param{attr_name: :foo,   parser: Maru.ParamType.String,  required: true, validators: [regexp: ~r/^[a-z]+$/], desc: "hehe"},
             %Param{attr_name: :group, parser: Maru.ParamType.List,    required: true, nested: true},
             %Param{attr_name: :group, parser: Maru.ParamType.Map,     required: true, nested: true, group: [:group]},
             %Param{attr_name: :bar,   parser: Maru.ParamType.Integer, required: false, group: [:group, :group], validators: [range: 1..100]}
           ] == OptionalTest.pc
  end


  test "validators" do
    defmodule ValidatorsTest do
      use Maru.Router

      params do
        mutually_exclusive [:a, :b, :c]
        group :group do
          exactly_one_of     [:a, :b, :c]
          at_least_one_of    [:a, :b, :c]
        end
      end
      def pc, do: @param_context
    end

    assert [ %Validator{action: :mutually_exclusive, attr_names: [:a, :b, :c], group: []},
             %Param{attr_name: :group, nested: true, parser: Maru.ParamType.List, required: true},
             %Validator{action: :exactly_one_of,     attr_names: [:a, :b, :c], group: [:group]},
             %Validator{action: :at_least_one_of,    attr_names: [:a, :b, :c], group: [:group]},
           ] == ValidatorsTest.pc
  end


  test "resources" do
    defmodule ResourcesTest do
      use Maru.Router
      resources :level1 do
        resource :level2 do
          route_param :param do
            def resource, do: @resource
          end
        end
      end
    end

    assert %Maru.Router.Resource{path: ["level1", "level2", :param]} = ResourcesTest.resource
  end

  test "complex resources" do
    defmodule ComplexResourcesTest do
      use Maru.Router
      resource "foo/:bar" do
        def resource, do: @resource
      end
    end

    assert %Maru.Router.Resource{path: ["foo", :bar]} = ComplexResourcesTest.resource
  end

  test "shared params" do
    defmodule Helper do
      use Maru.Helper
      params :foo0 do
        optional :bar
      end

      params :foo1 do
        requires :baz
      end
    end

    defmodule SharedParamsTest do
      use Maru.Router

      helpers Maru.RouterTest.Helper
      helpers do
        params :foo2 do
          optional :qux
        end
      end

      params do
        requires :foo
        use [:foo0, :foo1, :foo2]
      end

      def pc, do: @param_context
    end

    assert [
      %Maru.Router.Param{attr_name: :foo},
      %Maru.Router.Param{attr_name: :bar},
      %Maru.Router.Param{attr_name: :baz},
      %Maru.Router.Param{attr_name: :qux},
    ] = SharedParamsTest.pc
  end
end
