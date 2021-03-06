require 'spec_helper'
module Alf
  module Engine
    describe ToArray do

      subject{ ToArray.new(rel, ordering).to_a }

      context 'when ordering is nil' do
        let(:rel){[
          {name: "Jones", parts: Relation::DEE},
          {name: "Smith", parts: Relation::DUM}
        ]}
        let(:ordering){ nil }
        let(:expected){[
          {name: "Jones", parts: [{}]},
          {name: "Smith", parts: []}
        ]}

        it{ should eq(expected) }
      end

      context 'when both empty' do
        let(:rel)     { [] }
        let(:ordering){ Ordering::EMPTY }

        it{ should eq(rel) }
      end

      context 'when ascending on single attribute' do
        let(:rel){[
          {name: "Jones"},
          {name: "Smith"}
        ]}
        let(:ordering){ Ordering.new([[:name, :asc]]) }

        it{ should eq(rel) }
      end

      context 'when descending on single attribute' do
        let(:rel){[
          {name: "Jones"},
          {name: "Smith"}
        ]}
        let(:ordering){ Ordering.new([[:name, :desc]]) }

        it{ should eq(rel.reverse) }
      end

      context 'when TVAs are involved' do
        let(:rel){[
          {name: "Jones", hobby: { score: 10 }},
          {name: "Jones", hobby: { score: 12 }}
        ]}
        let(:ordering){ Ordering.new([[:name, :asc], [[:hobby, :score], :desc]]) }

        it{ should eq(rel.reverse) }
      end

      context 'when RVAs are involved' do
        let(:rel){[
          {name: "Smith", rva: Relation(id: [8, 7]) },
          {name: "Jones", rva: Relation(id: [1, 3]) }
        ]}
        let(:expected){[
          {name: "Jones", rva: [{id: 1}, {id: 3}] },
          {name: "Smith", rva: [{id: 7}, {id: 8}] }
        ]}
        let(:ordering){ Ordering.new([[:name, :asc], [[:rva, :id], :asc]]) }

        it{ should eq(expected) }
      end

    end # describe ToArray
  end # module Engine
end # module Alf
